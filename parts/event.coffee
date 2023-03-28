if Meteor.isClient
    Router.route '/calendar', (->
        @layout 'layout'
        @render 'cal'
        ), name:'cal'    
    Template.cal.onRendered ->
        # calendarEl = document.getElementById('cal')
        # calendar = new Calendar(calendarEl, {
        #   plugins: [
        #     interactionPlugin,
        #     dayGridPlugin
        #   ],
        #   initialView: 'timeGridWeek',
        #   editable: true,
        #   events: [
        #     { title: 'Meeting', start: new Date() }
        #   ]
        # })
        
        # calendar.render()
    @picked_event_tags = new ReactiveArray []

    Router.route '/event/:doc_id', (->
        @layout 'layout'
        @render 'event_view'
        ), name:'event_view'
        
    Router.route '/events', (->
        @layout 'layout'
        @render 'events'
        ), name:'events'
        
    Template.events.onCreated ->
        # @autorun => Meteor.subscribe 'model_docs', 'event', ->
        # @autorun => Meteor.subscribe 'event_tags',picked_tags.array(), ->
        Session.setDefault('viewing_past',false)
        Session.setDefault('event_search',null)
        Session.setDefault('view_mode','grid')
        Session.setDefault('sort_key','start_datetime')
        Session.setDefault('sort_direction',-1)

        @autorun => @subscribe 'event_facets',
            picked_tags.array()
            Session.get('viewing_past')
            Session.get('limit')
            Session.get('sort_key')
            Session.get('sort_direction')

        @autorun => @subscribe 'event_results',
            picked_tags.array()
            Session.get('viewing_past')
            Session.get('event_search')
            Session.get('limit')
            Session.get('sort_key')
            Session.get('sort_direction')
        
    # Router.route '/e/:doc_slug/', (->
    #     @layout 'layout'
    #     @render 'event_view'
    #     ), name:'event_view_by_slug'
        

    Template.registerHelper 'event_checkin_docs', () ->
        Docs.find 
            model:'checkin'
            event_id: Router.current().params.doc_id


    Template.event_view.onCreated ->
        @autorun => @subscribe 'event_tasks',Router.current().params.doc_id, ->
if Meteor.isServer  
    Meteor.publish 'event_checkins', (event_id)->
        Docs.find 
            model:'checkin'
            event_id:event_id
    Meteor.publish 'event_tasks', (event_id)->
        Docs.find 
            model:'task_instance'
            event_id:event_id

if Meteor.isClient  
    Template.session_icon_button.helpers
        session_icon_button_class: ->
            if Session.equals(@key,@value) then 'active' else 'basic compact'
    Template.session_icon_button.events
        'click .set_session_value': ->
            console.log 'hi'
            Session.set(@key,@value)
            
    Template.events.events
        'click .pick_tag': -> picked_tags.push @title
        'click .pick_flat_tag': -> picked_tags.push @valueOf()
        'click .unpick_tag': -> picked_tags.remove @valueOf()
        'click .toggle_past': ->
            Session.set('viewing_past', !Session.get('viewing_past'))
        # 'click .select_room': ->
        #     if Session.equals('viewing_room_id', @_id)
        #         Session.set('viewing_room_id', null)
        #     else
        #         Session.set('viewing_room_id', @_id)
        'click .add_event': ->
            new_id = 
                Docs.insert 
                    model:'event'
                    published:false
                    # purchased:false
            Router.go "/event/#{new_id}/edit"
        'keyup .event_search': _.throttle((e,t)->
            query = $('.event_search').val()
            Session.set('event_search', query)
            
            console.log Session.get('event_search')
            if e.which is 13
                search = $('.event_search').val().trim().toLowerCase()
                if search.length > 0
                    picked_event_tags.push search
                    console.log 'event_search', search
                    # Meteor.call 'log_term', search, ->
                    $('.event_search').val('')
                    Session.set('event_search', null)
                    # # $( "p" ).blur();
                    # Meteor.setTimeout ->
                    #     Session.set('dummy', !Session.get('dummy'))
                    # , 10000
        , 500)

            
    Template.events.helpers
        current_search: -> Session.get('event_search')
        event_tags: ->
            Results.find 
                model:'event_tag'
        picked_event_tags: -> picked_tags.array()
        
        one_event_result: ->
            # console.log moment().format()
            match = {}
            match.model = 'event'
            # published:true
            if picked_tags.array().length > 0
                match.tags = $all: picked_tags
            
            if Session.get('viewing_past')
                # match.date = $gt:moment().subtract(1,'days').format("YYYY-MM-DD")
                match.start_datetime = $lt:moment().subtract(1,'days').format()
            else if Session.get('view_mode', 'all')
                match.start_datetime = $gt:moment().subtract(1,'days').format()
            # else
            #     match.date = $lt:moment().subtract(1,'days').format("YYYY-MM-DD")
            if Session.get('event_search')
                match.title = {$regex:"#{Session.get('event_search')}", $options: 'i'}
            Docs.find(match).count() is 1
            
        two_event_results: ->
            # console.log moment().format()
            match = {}
            match.model = 'event'
            # published:true
            if picked_tags.array().length > 0
                match.tags = $all: picked_tags
            
            if Session.get('viewing_past')
                # match.date = $gt:moment().subtract(1,'days').format("YYYY-MM-DD")
                match.start_datetime = $lt:moment().subtract(1,'days').format()
            else if Session.get('view_mode', 'all')
                match.start_datetime = $gt:moment().subtract(1,'days').format()
            # else
            #     match.date = $lt:moment().subtract(1,'days').format("YYYY-MM-DD")
            if Session.get('event_search')
                match.title = {$regex:"#{Session.get('event_search')}", $options: 'i'}
            Docs.find(match).count() is 2
            
        
        viewing_past: -> Session.get('viewing_past')
        event_docs: ->
            # console.log moment().format()
            match = {}
            match.model = 'event'
            # published:true
            if picked_tags.array().length > 0
                match.tags = $all: picked_tags
            
            # if Session.get('viewing_past')
            #     # match.date = $gt:moment().subtract(1,'days').format("YYYY-MM-DD")
            #     match.start_datetime = $lt:moment().subtract(1,'days').format()
            # else if Session.get('view_mode', 'all')
            #     match.start_datetime = $gt:moment().subtract(1,'days').format()
            # else
            #     match.date = $lt:moment().subtract(1,'days').format("YYYY-MM-DD")
            if Session.get('event_search')
                match.title = {$regex:"#{Session.get('event_search')}", $options: 'i'}
            Docs.find match,
                sort:"#{Session.get('sort_key')}":parseInt(Session.get('sort_direction'))
    

if Meteor.isServer
    Meteor.publish 'future_events', ()->
        @unblock()
        console.log moment().subtract(1,'days').format("YYYY-MM-DD")
        Docs.find {
            model:'event'
            published:true
            date:$gt:moment().subtract(1,'days').format("YYYY-MM-DD")
        }, 
            sort:date:1
    
    Meteor.publish 'event_results', (
        picked_tags
        viewing_past=false
        event_search=''
        doc_limit
        doc_sort_key
        doc_sort_direction
        )->
        # console.log picked_tags
        if doc_limit
            limit = doc_limit
        else
            limit = 42
        if doc_sort_key
            sort_key = doc_sort_key
        if doc_sort_direction
            sort_direction = parseInt(doc_sort_direction)
        self = @
        match = {model:'event'}
        if viewing_past
            match.start_datetime = $lt:moment().subtract(1,'days').format()
            
        if picked_tags.length > 0
            match.tags = $all: picked_tags
            # sort = 'member_count'
        else
            sort = '_timestamp'
        if event_search.length > 0
            match.title = {$regex: "#{event_search}", $options: 'i'}
    
        # match.tags = $all: picked_tags
        # if filter then match.model = filter
        # keys = _.keys(prematch)
        # for key in keys
        #     key_array = prematch["#{key}"]
        #     if key_array and key_array.length > 0
        #         match["#{key}"] = $all: key_array
            # console.log 'current facet filter array', current_facet_filter_array

        # console.log 'group match', match
        # console.log 'sort key', sort_key
        # console.log 'sort direction', sort_direction
        Docs.find match,
            sort:"#{sort_key}":sort_direction
            # sort:_timestamp:-1
            limit: limit

    Meteor.publish 'event_facets', (
        picked_tags
        viewing_past=false
        event_search=''
        picked_timestamp_tags
        doc_limit
        doc_sort_key
        doc_sort_direction
        )->
        # console.log 'dummy', dummy
        # console.log 'query', query
        # console.log 'selected tags', picked_tags

        self = @
        match = {}
        match.model = 'event'
        # if view_open
        #     match.open = $ne:false
        if viewing_past
            match.start_datetime = $lt:moment().subtract(1,'days').format()

        if picked_tags.length > 0 then match.tags = $all: picked_tags
        if event_search.length > 0
            match.title = {$regex: "#{event_search}", $options: 'i'}
        event_count = Docs.find(match).count()
        console.log event_count, 'count'

        tag_cloud = Docs.aggregate [
            { $match: match }
            { $project: "tags": 1 }
            { $unwind: "$tags" }
            { $group: _id: "$tags", count: $sum: 1 }
            { $match: _id: $nin: picked_tags }
            { $match: count: $lt: event_count }
            # { $match: _id: {$regex:"#{event_search}", $options: 'i'} }
            { $sort: count: -1, _id: 1 }
            { $limit: 15 }
            { $project: _id: 0, title: '$_id', count: 1 }
        ], {
            allowDiskUse: true
        }

        tag_cloud.forEach (tag, i) =>
            # console.log 'tag result ', tag
            self.added 'results', Random.id(),
                title: tag.title
                count: tag.count
                model:'event_tag'
                # category:key
                # index: i


        self.ready()

    # Meteor.publish 'doc_by_slug', (slug)->
    #     Docs.find
    #         slug:slug
            
    Meteor.publish 'author_by_doc_id', (doc_id)->
        doc_by_id =
            Docs.findOne doc_id
        doc_by_slug =
            Docs.findOne slug:doc_id
        if doc_by_id
            Meteor.users.find
                _id:doc_by_id._author_id
        else
            Meteor.users.find
                _id:doc_by_slug._author_id
            
            
    # Meteor.publish 'author_by_doc_slug', (slug)->
    #     doc = 
    #         Docs.findOne
    #             slug:slug
    #     Meteor.users.findOne 
    #         _id:doc._author_id



if Meteor.isClient
    Template.event_view.onCreated ->
        @autorun => Meteor.subscribe 'doc_by_id', Router.current().params.doc_id
        @autorun => Meteor.subscribe 'author_by_doc_id', Router.current().params.doc_id
        # @autorun => Meteor.subscribe 'author_by_doc_slug', Router.current().params.doc_slug

    Template.event_view.onCreated ->
        @autorun => Meteor.subscribe 'event_tickets', Router.current().params.doc_id
        # @autorun => Meteor.subscribe 'model_docs', 'room'
        
        # if Meteor.isDevelopment
        #     pub_key = Meteor.settings.public.stripe_test_publishable
        # else if Meteor.isProduction
        #     pub_key = Meteor.settings.public.stripe_live_publishable
        # Template.instance().checkout = StripeCheckout.configure(
        #     key: pub_key
        #     image: 'https://res.cloudinary.com/facet/image/upload/v1585357133/one_logo.png'
        #     locale: 'auto'
        #     zipCode: true
        #     token: (token) =>
        #         # amount = parseInt(Session.get('topup_amount'))
        #         event = Docs.findOne Router.current().params.doc_id
        #         charge =
        #             amount: Session.get('usd_paying')*100
        #             event_id:event._id
        #             currency: 'usd'
        #             source: token.id
        #             input:'number'
        #             # description: token.description
        #             description: "one"
        #             event_title:event.title
        #             # receipt_email: token.email
        #         Meteor.call 'buy_ticket', charge, (err,res)=>
        #             if err then alert err.reason, 'danger'
        #             else
        #                 console.log 'res', res
        #                 Swal.fire(
        #                     'ticket purchased',
        #                     ''
        #                     'success'
        #                 # Meteor.users.update Meteor.userId(),
        #                 #     $inc: points:500
        #                 )
        # )
    
    Template.event_view.onRendered ->
        Docs.update Router.current().params.doc_id, 
            $inc: views: 1

    Template.event_view.helpers 
        can_buy: ->
            now = Date.now()
        _task: ->
            Docs.findOne 
                _id:@task_id
        task_instance: ->
            Docs.findOne 
                model:'task_instance'
                task_id:@_id
                event_id:Router.current().params.doc_id
                
    Template.event_view.events
        'click .generate_task': ->
            # console.log @
            Docs.insert 
                model:'task_instance'
                event_id:Router.current().params.doc_id
                task_id:@_id
            $('body').toast(message:'task created')
        'click .buy_for_points': (e,t)->
            val = parseInt $('.point_input').val()
            Session.set('point_paying',val)
            # $('.ui.modal').modal('show')
            Swal.fire({
                title: "buy ticket for #{Session.get('point_paying')}pts?"
                text: "#{@title}"
                icon: 'question'
                # input:'number'
                confirmButtonText: 'purchase'
                confirmButtonColor: 'green'
                showCancelButton: true
                cancelButtonText: 'cancel'
                reverseButtons: true
            }).then((result)=>
                if result.value
                    Docs.insert 
                        model:'transaction'
                        transaction_type:'ticket_purchase'
                        payment_type:'points'
                        is_points:true
                        point_amount:Session.get('point_paying')
                        event_id:@_id
                    Meteor.users.update Meteor.userId(),
                        $inc:points:-Session.get('point_paying')
                    Meteor.users.update @_author_id, 
                        $inc:points:Session.get('point_paying')
                    Swal.fire(
                        position: 'top-end',
                        icon: 'success',
                        title: 'ticket purchased',
                        showConfirmButton: false,
                        timer: 1500
                    )
            )
        
        'click .return': (e,t)->
            # val = parseInt $('.point_input').val()
            # Session.set('point_paying',val)
            # $('.ui.modal').modal('show')
            Swal.fire({
                title: "return ticket?"
                # text: "#{Template.parentData().title}"
                icon: 'question'
                # input:'number'
                confirmButtonText: 'return'
                confirmButtonColor: 'orange'
                showCancelButton: true
                cancelButtonText: 'cancel'
                reverseButtons: true
            }).then((result)=>
                if result.value
                    Docs.remove @_id
                    Swal.fire(
                        position: 'top-end',
                        icon: 'success',
                        title: 'ticket returned',
                        showConfirmButton: false,
                        timer: 1500
                    )
            )
    
        'click .buy_for_usd': (e,t)->
            console.log Template.instance()
            val = parseInt t.$('.usd_input').val()
            Session.set('usd_paying',val)

            instance = Template.instance()

            Swal.fire({
                # title: "buy ticket for $#{@usd_price} or more!"
                title: "buy ticket for $#{Session.get('usd_paying')}?"
                text: "for #{@title}"
                icon: 'question'
                showCancelButton: true,
                confirmButtonText: 'purchase'
                # input:'number'
                confirmButtonColor: 'green'
                showCancelButton: true
                cancelButtonText: 'cancel'
                reverseButtons: true
            }).then((result)=>
                if result.value
                    # Session.set('topup_amount',5)
                    # Template.instance().checkout.open
                    instance.checkout.open
                        name: 'jam night'
                        # email:Meteor.user().emails[0].address
                        description: "#{@title} ticket purchase"
                        amount: Session.get('usd_paying')*100
            
                    # Meteor.users.update @_author_id,
                    #     $inc:credit:@order_price
                    # Swal.fire(
                    #     'topup initiated',
                    #     ''
                    #     'success'
                    # )
            )
    
    Template.event_view.helpers
        tickets_left: ->
            ticket_count = 
                Docs.find({ 
                    model:'transaction'
                    transaction_type:'ticket_purchase'
                    event_id: Router.current().params.doc_id
                }).count()
            @max_attendees-ticket_count



# if Meteor.isServer
#     Meteor.publish 'event_tickets', (event_id)->
#         Docs.find
#             model:'transaction'
#             transaction_type:'ticket_purchase'
#             event_id:event_id


if Meteor.isClient
    Router.route '/event/:doc_id/edit', (->
        @layout 'layout'
        @render 'event_edit'
        ), name:'event_edit'

    Template.event_edit.onCreated ->
        @autorun => Meteor.subscribe 'doc_by_id', Router.current().params.doc_id, ->

    Template.event_edit.events
        'click .delete_item': ->
            if confirm 'delete item?'
                Docs.remove @_id