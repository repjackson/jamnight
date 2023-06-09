# @picked_sections = new ReactiveArray []
@picked_tags = new ReactiveArray []
@picked_user_tags = new ReactiveArray []
@picked_timestamp_tags = new ReactiveArray []
# @picked_ingredients = new ReactiveArray []

Template.nav.onCreated ->
    Meteor.subscribe 'me', ->
Template.home.onCreated ->
    Meteor.subscribe 'event_task_instances',Session.get('current_checkin_id'), ->
    # Meteor.subscribe 'model_docs','event', ->
    Meteor.subscribe 'current_event', ->
    
    Meteor.subscribe 'model_docs','checkin', ->
    Meteor.subscribe 'model_docs','task', ->
    Meteor.subscribe 'current_event_task_instances', ->
    Meteor.subscribe 'all_users', ->

Template.home.events
    'keyup .user_input': (e,t)->
        search_value = $(e.currentTarget).closest('.user_input').val().trim()
        if search_value.length > 1
            Session.set('user_query',search_value)
        if e.which is 13
            query = Session.get('user_query')
            slugged = query.toString().toLowerCase().replace(/\s+/g, '_').replace(/[^\w\-]+/g, '').replace(/\-\-+/g, '_').replace(/^-+/, '').replace(/-+$/,'')
            count = Meteor.users.find({
                $or: [
                    {username:$regex:"#{Session.get('user_query')}", $options: 'i'}
                    {name:$regex:"#{Session.get('user_query')}", $options: 'i'}
                    ]
                }).count()
            if count is 1
                found_user = Meteor.users.findOne({
                    $or: [
                        {username:$regex:"#{Session.get('user_query')}", $options: 'i'}
                        {name:$regex:"#{Session.get('user_query')}", $options: 'i'}
                        ]
                    })
                Docs.update Session.get('current_checkin_id'),
                    $set:user_id:found_user._id
            else if count is 0
                options = {
                    username:slugged
                    password:slugged
                    }
                console.log options
                Meteor.call 'create_user', options, (err,res)=>
                    if err
                        alert err
                    else
                        console.log res
                        user = Meteor.users.findOne res
                        Meteor.users.update res,
                            $set:
                                name:query
                                checked_in:true
                                last_checkin:Date.now()
                        Docs.update Session.get('current_checkin_id'),
                            $set:
                                user_id:res
                                username:user.username
                                name:user.name

    'click .complete_checkin': ->
        Docs.update Session.get('current_checkin_id'),
            $set:
                complete:true 
                active:true
        Session.set('current_checkin_id',null)
        $('body').toast(
            showIcon: 'checkmark'
            message: "saved"
            showProgress: 'bottom'
            class: 'success'
            # displayTime: 'auto',
            position: "bottom center"
        )
        Session.set 'user_query', null
    'click .cancel_checkin': ->
        Docs.remove Session.get('current_checkin_id')
    'click .new_checkin': ->
        new_id = 
            Docs.insert 
                model:'checkin'
        Session.set('current_checkin_id',new_id)
        current_event = Docs.findOne 
            model:'event'
            current:true
        Docs.update Session.get('current_checkin_id'),
            $set:
                event_id:current_event._id
    'click .pick_task': ->
        cd = Docs.findOne Session.get('current_checkin_id')
        if cd.task_ids
            if @_id in cd.task_ids
                Docs.update Session.get('current_checkin_id'),
                    $pull:task_ids:@_id 
            else             
                Docs.update Session.get('current_checkin_id'),
                    $addToSet:task_ids:@_id 
        else 
            Docs.update Session.get('current_checkin_id'),
                $addToSet:task_ids:@_id 
    # 'click .pick_event': ->
    #     cd = Docs.findOne Session.get('current_checkin_id')
    #     unless @_id is cd.event_id
    #         Docs.update Session.get('current_checkin_id'),
    #             $set:
    #                 event_id:@_id 
    #     else             
    #         Docs.update Session.get('current_checkin_id'),
    #             $unset:
    #                 event_id:1 
    'click .pick_user': ->
        cd = Docs.findOne Session.get('current_checkin_id')
        # if @_id is cd.user_id
        Meteor.users.update @_id, 
            $set:
                checked_in:true
                last_checkin:Date.now()
        Docs.update Session.get('current_checkin_id'),
            $set:
                user_id:@_id 
                name:@name
                username:@username
        if @is_musician
            Docs.update Session.get('current_checkin_id'),
                $set:checkin_type:'musician' 
    'click .checkout': ->
        Docs.update @_id, 
            $set:
                active:false 
                checkout_timestamp:Date.now()
        Meteor.users.update @user_id,
            $set:
                checked_in:false
        $('body').toast(
            showIcon: 'checkmark'   
            message: "checked out"
            showProgress: 'bottom'
            class: 'success'
            # displayTime: 'auto',
            position: "bottom center"
        )

    'click .unpick_user': ->
        cd = Docs.findOne Session.get('current_checkin_id')
        Docs.update Session.get('current_checkin_id'),
            $unset:user_id:1 
    'click .add_user': ->
        query = Session.get('user_query')
        slugged = query.toString().toLowerCase().replace(/\s+/g, '_').replace(/[^\w\-]+/g, '').replace(/\-\-+/g, '_').replace(/^-+/, '').replace(/-+$/,'')

        options = {
            username:slugged
            password:slugged
            }
        console.log options
        Meteor.call 'create_user', options, (err,res)=>
            if err
                alert err
            else
                console.log res
                user = Meteor.users.findOne res
                Meteor.users.update res,
                    $set:
                        name:query
                        checked_in:true 
                        last_checkin:Date.now()
                Docs.update Session.get('current_checkin_id'),
                    $set:
                        user_id:res
                        username:user.username 
                        name:user.name

Template.home.helpers
    user_query: -> Session.get('user_query')
    picked_user: ->
        cd = Docs.findOne Session.get('current_checkin_id')
        Meteor.users.findOne cd.user_id
    # event_button_class: ->
    #     cd = Docs.findOne Session.get('current_checkin_id')
    #     if @_id is cd.event_id then 'blue' else 'basic compact'
    task_class: ->
        cd = Docs.findOne Session.get('current_checkin_id')
        if @_id in cd.task_ids then 'blue' else 'basic compact'
    user_class: ->
        cd = Docs.findOne Session.get('current_checkin_id')
        if @_id is cd.user_id then 'blue' else 'basic compact'
    can_complete: ->
        cd = Docs.findOne Session.get('current_checkin_id')
        if cd.checkin_type
            if cd.checkin_type is 'audience'
                true
            else if cd.checkin_type is 'musician'
                if cd.musician_type
                    true 
            else if cd.checkin_type is 'volunteer'
                if cd.task_ids.length>0
                    true
    user_docs: ->
        # match = {}
        if Session.get('user_query')
            # match.username = 
            Meteor.users.find({
                $and: [
                    # checked_in:$ne:true
                    $or: [
                        {username:$regex:"#{Session.get('user_query')}", $options: 'i'}
                        {name:$regex:"#{Session.get('user_query')}", $options: 'i'}
                    ]
                ]
                })
        else 
            Meteor.users.find({
                # checked_in:$ne:true
                })
    parent_event: ->
        Docs.findOne 
            model:'task'
            _id:@task_id
    current_checkin: ->
        Docs.findOne 
            _id:Session.get('current_checkin_id')
    event_docs: ->
        cd = Docs.findOne Session.get('current_checkin_id')
        if cd.event_id
            Docs.find _id:cd.event_id
        else 
            Docs.find
                model:'event'
    event_tasks: ->
        cd = Docs.findOne Session.get('current_checkin_id')
        current_event = Docs.findOne 
            model:'event'
            current:true
        Docs.find 
            event_id:cd.event_id
            model:'task_instance'
    slots_left: ->
        console.log @
        parent_task = Docs.findOne @task_id
        parent_task.slot_amount>0
    checkin_docs: ->
        Docs.find {
            model:'checkin'
        }, sort:_timestamp:-1
Template.layout.events 
    'click .clear_search': -> 
        Session.set('user_query',null)
        picked_tags.clear()
Tracker.autorun ->
    current = Router.current()
    Tracker.afterFlush ->
        $(window).scrollTop 0


Template.footer.helpers
    doc_docs: ->
        Docs.find {}
    result_docs: ->
        Results.find {}

    user_docs: ->
        Meteor.users.find()
        
        
Template.not_found.events
    'click .browser_back': -> window.history.back();



$.cloudinary.config
    cloud_name:"facet"
# Router.notFound =
    # action: 'not_found'

Template.layout.events
    'click .fly_right': (e,t)-> 
        # console.log 'hi'
        $(e.currentTarget).closest('.grid').transition('fly right', 500)
    'click .fly_up': (e,t)-> $(e.currentTarget).closest('.grid').transition('fly up', 1000)
    'click .fly_down': (e,t)-> $(e.currentTarget).closest('.grid').transition('fly down', 1000)
    'click .fly_left': (e,t)-> $(e.currentTarget).closest('.grid').transition('fly left', 1000)
    # 'click .button': ->
    #     $(e.currentTarget).closest('.button').transition('bounce', 1000)

    'click a': ->
        $('.global_container')
        .transition('fade out', 200)
        .transition('fade in', 200)

    'click .log_view': ->
        # console.log Template.currentData()
        # console.log @
        Docs.update @_id,
            $inc: views: 1

# Template.layout.events
#     'click .button': ->
#         $('.global_container')
#         .transition('fade out', 10000)
#         .transition('fade in', 5000)


# Tracker.autorun ->
#     current = Router.current()
#     Tracker.afterFlush ->
#         $(window).scrollTop 0


# Stripe.setPublishableKey Meteor.settings.public.stripe_publishable
