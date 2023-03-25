# @picked_sections = new ReactiveArray []
@picked_tags = new ReactiveArray []
@picked_user_tags = new ReactiveArray []
@picked_timestamp_tags = new ReactiveArray []
# @picked_ingredients = new ReactiveArray []

Template.home.onCreated ->
    Meteor.subscribe 'model_docs','checkin', ->
    Meteor.subscribe 'model_docs','task', ->
    Meteor.subscribe 'model_docs','all_users', ->

Template.home.events
    'click .complete_checkin': ->
        Docs.update Session.get('current_checkin_id'),
            $set:
                complete:true 
        Session.set('current_checkin_id',null)
        $('body').toast(
            showIcon: 'checkmark'
            message: "saved"
            showProgress: 'bottom'
            class: 'success'
            # displayTime: 'auto',
            position: "bottom center"
        )

        
    'click .cancel_checkin': ->
        Docs.remove Session.get('current_checkin_id')
    'click .new_checkin': ->
        new_id = 
            Docs.insert 
                model:'checkin'
        Session.set('current_checkin_id',new_id)
    'click .pick_task': ->
        cd = Docs.findOne Session.get('current_checkin_id')
        if @_id in cd.task_ids
            Docs.update Session.get('current_checkin_id'),
                $pull:
                    task_ids:@_id 
        else             
            Docs.update Session.get('current_checkin_id'),
                $addToSet:
                    task_ids:@_id 
    'click .pick_user': ->
        cd = Docs.findOne Session.get('current_checkin_id')
        if @_id is cd.user_id
            Docs.update Session.get('current_checkin_id'),
                $unset:user_id:1 
        else             
            Docs.update Session.get('current_checkin_id'),
                $set:user_id:@_id 
        
Template.home.helpers
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
        Meteor.users.find()
    current_checkin: ->
        Docs.findOne 
            _id:Session.get('current_checkin_id')
    home_docs: ->
        Docs.find 
            model:'post'
            home:true

Template.layout.events 
    'click .clear_search': -> 
        Session.set('event_search',null)
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
# Template.home.onCreated ->
#     @autorun => @subscribe 'model_docs', 'stats', ->
# Template.home.onRendered ->
#     Meteor.call 'log_homepage_view', ->
#         console.log '?'
# Template.home.helpers
#     stats: ->
#         Docs.findOne
#             model:'stats'

# Template.nav.onCreated ->
#     @autorun => @subscribe 'order_count'
#     @autorun => @subscribe 'product_count'
#     @autorun => @subscribe 'ingredient_count'
#     @autorun => @subscribe 'subscription_count'
#     @autorun => @subscribe 'source_count'
#     @autorun => @subscribe 'giftcard_count'
#     @autorun => @subscribe 'user_count'
        
        
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
