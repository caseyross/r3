import { iframes } from '../../../config/integrations.js'
import { fetchPostComments } from '../../logic/API.coffee'
import Flair from './Flair.coffee'
import Subreddit from './Subreddit.coffee'

export default class Post

	constructor: (data) -> @[k] = v for k, v of {

		id: data.id.toPostId()
		subreddit: new Subreddit(data.sr_detail)
		crosspostParent: data.crosspost_parent_list
		href: '/r/' + data.subreddit + '/post/' + data.id.toShortId()

		authorName: data.author
		authorFlair: new Flair
			text: data.author_flair_text
			color: data.author_flair_background_color
		authorRole: data.distinguished
		
		createDate: new Date(Date.seconds(data.created_utc))
		editDate: if data.edited then new Date(Date.seconds(data.edited)) else null

		title: data.title
		titleFlair: new Flair
			text: data.link_flair_text
			color: data.link_flair_background_color
		domain: data.domain
		content: new PostContent(data)
		isContestMode: data.contest_mode
		isNSFW: data.over_18
		isOC: data.is_original_content
		isSpoiler: data.spoiler
		isArchived: data.archived
		isLocked: data.locked
		isQuarantined: data.quarantine
		isStickied: data.stickied
		wasDeleted: data.selftext is '[removed]'

		score: if data.hide_score then NaN else data.score - 1
		myVote: switch data.likes
			when true then 1
			when false then -1
			else 0
		mySave: data.saved
		myHide: data.hidden

		commentCount: data.num_comments
		comments: fetchPostComments(data.id.toPostId())

	}

PostContent = (data) ->
	@type = 'LINK'
	@href = data.url
	switch
		when data.media?.reddit_video
			@type = 'VIDEO_NATIVE'
			@video = new Video(data.media.reddit_video)
		when data.is_gallery
			@type = 'IMAGE_NATIVE'
			@images = data.gallery_data.items.map (x) ->
				new Image { ...data.media_metadata[x.media_id], caption: x.caption, link: x.outbound_url }
		when data.post_hint is 'image'
			@type = 'IMAGE_NATIVE'
			@images = [ new Image(data.preview.images[0]) ]
		when data.is_self
			@type = 'TEXT'
			@text = data.selftext_html
		else
			url = new URL(if data.url.startsWith 'https' then data.url else 'https://www.reddit.com' + data.url)
			switch
				when data.domain is 'i.redd.it'
					@type = 'IMAGE_NATIVE'
					@images = [ new Image { p: [], s: [{ u: data.url }] } ]
				when iframes[data.domain] and iframes[data.domain](url)
					@type = 'VIDEO_IFRAME'
					@src = iframes[data.domain](url).src
					@allow = iframes[data.domain](url).allow or ''
				when data.domain.endsWith 'reddit.com'
					[ _, _, _, _, postShortId, _, commentShortId ] = url.pathname.split('/')
					@type = 'REDDIT'
					@postId = postShortId?.toPostId()
					@commentId = commentShortId?.toCommentId()
	return @