if Meteor.isClient
    Template.nav.onCreated ->
        @autorun => Meteor.subscribe 'me', ->
        @autorun => Meteor.subscribe 'all_users',->
        @autorun => Meteor.subscribe 'model_docs','task',->
        # @autorun => Meteor.subscribe 'models', ->
        

    Template.nav.onRendered ->
        Meteor.setTimeout ->
            $('.menu .item')
                .popup()
        , 5000
                
    Template.nav.events
        'click .reset': ->
            # model_slug =  Router.current().params.model_slug
            Session.set 'loading', true
            Meteor.call 'set_facets', @slug, true, ->
                Session.set 'loading', false
    
        'click .clear_search': -> Session.set('product_query',null)
        'keyup .search_products': _.throttle((e,t)->
            # console.log Router.current().route.getName()
            current_name = Router.current().route.getName()
            # $(e.currentTarget).closest('.input').transition('pulse', 100)

            unless current_name is 'shop'
                Router.go '/shop'
            query = $('.search_products').val()
            Session.set('product_query', query)
            # console.log Session.get('product_query')
            if e.key == "Escape"
                Session.set('product_query', null)
                
            if e.which is 13
                search = $('#product_search').val().trim().toLowerCase()
                if search.length > 0
                    picked_tags.push search
                    console.log 'search', search
                    # Meteor.call 'log_term', search, ->
                    $('#product_search').val('')
                    Session.set('product_query', null)
                    # # $('#search').val('').blur()
                    # # $( "p" ).blur();
                    # Meteor.setTimeout ->
                    #     Session.set('dummy', !Session.get('dummy'))
                    # , 10000
        , 500)
    
        'click .alerts': ->
            Session.set('viewing_alerts', !Session.get('viewing_alerts'))
            
        'click .toggle_admin': ->
            if 'admin' in Meteor.user().roles
                Meteor.users.update Meteor.userId(),
                    $pull:'roles':'admin'
            else
                Meteor.users.update Meteor.userId(),
                    $addToSet:'roles':'admin'
        'click .invert_toggle': ->
            # console.log 'hi'
            $('.item').transition('pulse', '1000')
            # $('.menu').transition('pulse', '1000')
            $('body').toggleClass('invert')
            # Meteor.users.update Meteor.userId(),
            #     $set:admin_mode:!Meteor.user().admin_mode
        'click .toggle_dev': ->
            if 'dev' in Meteor.user().roles
                Meteor.users.update Meteor.userId(),
                    $pull:'roles':'dev'
            else
                Meteor.users.update Meteor.userId(),
                    $addToSet:'roles':'dev'
        'click .view_user': ->
            Meteor.call 'calc_user_points', Meteor.userId(), ->
            
        'click .clear_tags': -> picked_tags.clear()
    
    Template.nav.helpers
        product_counter: -> Counts.get('product_counter')
        
        current_product_search: -> Session.get('product_query')
        unread_count: ->
            unread_count = Docs.find({
                model:'message'
                to_username:Meteor.user().username
                read_by_ids:$nin:[Meteor.userId()]
            }).count()

        cart_amount: ->
            cart_amount = Docs.find({
                model:'cart_item'
                status:'cart'
                _author_id:Meteor.userId()
            }).count()
        cart_items: ->
            # co = 
            #     Docs.findOne 
            #         model:'order'
            #         status:'cart'
            #         _author_id:Meteor.userId()
            # if co 
            Docs.find 
                model:'cart_item'
                _author_id: Meteor.userId()
                # order_id:co._id
                # status:'cart'
                
        alert_toggle_class: ->
            if Session.get('viewing_alerts') then 'active' else ''
        unread_count: ->
            Docs.find( 
                model:'message'
                recipient_id:Meteor.userId()
                read_ids:$nin:[Meteor.userId()]
            ).count()
    Template.nav.events
        'mouseenter a': (e,t)-> $(e.currentTarget).closest('a').transition('pulse', '1000')
        'mouseenter a': (e,t)-> $(e.currentTarget).closest('a').transition('pulse', '1000')

if Meteor.isServer
    Meteor.publish 'my_cart', ->
        Docs.find 
            model:'cart_item'
