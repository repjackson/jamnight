Meteor.users.allow
    insert: (userId, doc) -> 
        userId    
        # doc._author_id is userId
    update: (userId, doc, fields, modifier) ->
        true
        # if userId and doc._id == userId
        #     true
    remove: (userId, doc) -> 
        userId
        # doc._author_id is userId or 'admin' in Meteor.user().roles


Docs.allow
    insert: (userId, doc) -> 
        userId    
        # doc._author_id is userId
    update: (userId, doc) ->
        userId
        # if doc.model in ['calculator_doc','simulated_rental_item','healthclub_session']
        #     userId
        # else if Meteor.user() and Meteor.user().roles and 'admin' in Meteor.user().roles
        #     userId
        # else
        #     doc._author_id is userId
    # update: (userId, doc) -> doc._author_id is userId or 'admin' in Meteor.user().roles
    remove: (userId, doc) -> 
        userId
        # doc._author_id is userId or 'admin' in Meteor.user().roles

Meteor.publish 'event_task_instances', (checkin_id)->
    if checkin_id
        checkin_doc = Docs.findOne checkin_id
        if checkin_doc.event_id 
            Docs.find 
                model:'task_instance'
                event_id:checkin_doc.event_id
Meteor.publish 'current_event', ()->
    Docs.find 
        model:'event'
        current:true
Meteor.publish 'current_event_task_instances', ()->
    current_event = 
        Docs.findOne 
            model:'event'
            current:true
    if current_event
        Docs.find 
            model:'task_instance'
            event_id:current_event._id
Meteor.publish 'docs', (picked_tags, filter)->
    # user = Meteor.users.findOne @userId
    # console.log picked_tags
    # console.log filter
    self = @
    match = {}
    # if Meteor.user()
    #     unless Meteor.user().roles and 'dev' in Meteor.user().roles
    #         match.view_roles = $in:Meteor.user().roles
    # else
    #     match.view_roles = $in:['public']

    # if filter is 'shop'
    #     match.active = true
    if picked_tags.length > 0 then match.tags = $all: picked_tags
    if filter then match.model = filter

    Docs.find match, sort:_timestamp:-1


# Meteor.users.allow
#     update: (userId, doc, fields, modifier) ->
#         true
#         # if userId and doc._id == userId
#         #     true

Cloudinary.config
    cloud_name: 'facet'
    api_key: Meteor.settings.private.cloudinary_key
    api_secret: Meteor.settings.private.cloudinary_secret



Meteor.publish 'all_users', ()->
    Meteor.users.find {}, {
        # fields:
        #     username:1
        #     image_id:1
        #     tags:1
        #     first_name:1
        #     last_name:1
    }
            
    
Meteor.publish 'model_docs', (model,limit)->
    match = {}
    unless Meteor.userId()
        match.private = $ne:true
    match.model = model
    if limit
        Docs.find match, 
            limit:limit
    else
        Docs.find match , sort:_timestamp:-1
Meteor.publish 'me', ->
    Meteor.users.find({_id:@userId},{
        # fields:
        #     username:1
        #     image_id:1
        #     tags:1
        #     points:1
    })

Meteor.publish 'document_by_slug', (slug)->
    Docs.find
        model: 'document'
        slug:slug

Meteor.publish 'child_docs', (id)->
    Docs.find
        parent_id:id


Meteor.publish 'facet_doc', (tags)->
    split_array = tags.split ','
    Docs.find
        tags: split_array


Meteor.publish 'inline_doc', (slug)->
    Docs.find
        model:'inline_doc'
        slug:slug



Meteor.publish 'user_from_username', (username)->
    Meteor.users.find username:username

Meteor.publish 'user_from_id', (user_id)->
    Meteor.users.find user_id

Meteor.publish 'doc_by_id', (doc_id)->
    Docs.find doc_id

Meteor.publish 'author_from_doc_id', (doc_id)->
    doc = Docs.findOne doc_id
    Meteor.users.find doc._author_id

# Meteor.publish 'page', (slug)->
#     Docs.find
#         model:'page'
#         slug:slug


Meteor.publish 'doc_tags', (picked_tags)->
    user = Meteor.users.findOne @userId
    # current_herd = user.user.current_herd

    self = @
    match = {}

    # picked_tags.push current_herd
    match.tags = $all: picked_tags

    cloud = Docs.aggregate [
        { $match: match }
        { $project: tags: 1 }
        { $unwind: "$tags" }
        { $group: _id: '$tags', count: $sum: 1 }
        { $match: _id: $nin: picked_tags }
        { $sort: count: -1, _id: 1 }
        { $limit: 20 }
        { $project: _id: 0, name: '$_id', count: 1 }
        ]
    cloud.forEach (tag, i) ->

        self.added 'tags', Random.id(),
            name: tag.name
            count: tag.count
            index: i

    self.ready()



Meteor.publish 'user_count', (
    )->
    @unblock()
    Counts.publish this, 'user_count', Meteor.users.find({})
    return undefined
Meteor.publish 'model_count', (
    model=null
    )->
    @unblock()
    if model
        match = {model:model}
        Counts.publish this, "#{model}_counter", Docs.find(match)
        return undefined



# if Meteor.isServer
    # Meteor.startup () ->
        # Meteor.users.dropIndexes()
        # Meteor.users._ensureIndex({ "location": '2dsphere'});
    
    
    # Meteor.methods
    #     tag_coordinates: (doc_id, lat,long)->
    #         # HTTP.get "https://api.opencagedata.com/geocode/v1/json?q=#{lat}%2C#{long}&key=f234c66b8ec44a448f8cb6a883335718&language=en&pretty=1&no_annotations=1",(err,response)=>
    #         HTTP.get "https://api.opencagedata.com/geocode/v1/json?q=#{lat}+#{long}&key=7c21b934bda2463a94bcd5ff74647374&language=en&pretty=1&no_annotations=1",(err,response)=>
    #             console.log response.data
    #             if err then console.log err
    #             else
    #                 doc = Docs.findOne doc_id
    #                 user = Meteor.users.findOne doc_id
    #                 if doc
    #                     Docs.update doc_id,
    #                         $set:geocoded:response.data.results
    #                 if user
    #                     Meteor.users.update doc_id,
    #                         $set:geocoded:response.data.results
    #                 console.log 'working', response
    
    #         # https://api.opencagedata.com/geocode/v1/json?q=24.77701%2C%20121.02189&key=f234c66b8ec44a448f8cb6a883335718&language=en&pretty=1&no_annotations=1
    #         # https://api.opencagedata.com/geocode/v1/json?q=Dhumbarahi%2C%20Kathmandu&key=f234c66b8ec44a448f8cb6a883335718&language=en&pretty=1&no_annotations=1
    
    
    # # Meteor.publish 'nearby_people', (lat,long)->
    # Meteor.publish 'nearby_people', (username)->
    #     user = Meteor.users.findOne username:username
        
    #     if user
    #         console.log 'searching for users lat long', user.current_lat, user.current_long
    #         Meteor.users.find
    #             light_mode:true
    #             location:
    #                 $near:
    #                     $geometry:
    #                         type: "Point"
    #                         coordinates: [user.current_long, user.current_lat]
    #                         $maxDistance: 2000