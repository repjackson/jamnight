if Meteor.isClient
    Router.route '/user/:username', (->
        @layout 'layout'
        @render 'user'
        ), name:'user'

    Template.user.onCreated ->
        @autorun -> Meteor.subscribe 'user_from_username', Router.current().params.username, ->
        @autorun -> Meteor.subscribe 'user_checkins', Router.current().params.username, ->
    Template.user_credit.events
        'click .send_credit': ->
            user = Meteor.users.findOne username:Router.current().params.username
            new_id = 
                Docs.insert 
                    model:'transfer'
                    recipient_id:user._id
                    recipient_username:user.username
            Router.go "/transfer/#{new_id}/edit"
                
    Template.user.helpers
        current_user: ->
            Meteor.users.findOne username:Router.current().params.username
    
    Template.user_checkins.helpers
        user_checkin_docs: ->
            current_user = Meteor.users.findOne(username:Router.current().params.username)
            Docs.find {
                model:'checkin'
                user_id:current_user._id
            }, 
                sort: _timestamp:-1
                limit: 10
    Template.user.helpers
        user_tasks: ->
            current_user = Meteor.users.findOne(username:Router.current().params.username)
            Docs.find {
                model:'task_instance'
                user_ids:current_user._id
            }, 
                sort: _timestamp:-1
                limit: 10


if Meteor.isClient 
    Template.user.onRendered ->
        Meteor.setTimeout ->
            $('.button').popup()
        , 2000

    Template.user.events
        'click .logout_other_clients': ->
            Meteor.logoutOtherClients()

        'click .logout': ->
            Router.go '/login'
            Meteor.logout()
            
            
if Meteor.isServer
    Meteor.methods
        'calc_user_credit': (user_id)->
            total_credit = 0
            topups = 
                Docs.find 
                    model:'credit'
                    _author_id:Meteor.userId()
                    amount:$exists:true
            for topup in topups.fetch()
                total_credit += topup.amount
            console.log total_points
            
            Meteor.users.update Meteor.userId(),
                $set:credit:total_points
            
            
    Meteor.publish 'username_model_docs', (username, model)->
        user = Meteor.users.findOne username:username
        # if username 
        Docs.find {
            model:model
            _author_id:user._id
        }, limit:20
        # else 
        #     Docs.find   
        #         model:model
        #         _author_username:Meteor.user().username            
    Meteor.publish 'user_checkins', (username)->
        user = Meteor.users.findOne username:username
        if user
            Docs.find({
                model:'checkin'
                user_id:user._id
            },{
                limit:20
                sort: _timestamp:-1
            })
        
        
            
            