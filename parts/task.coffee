if Meteor.isClient
    Router.route '/tasks', (->
        @layout 'layout'
        @render 'tasks'
        ), name:'tasks'
    Router.route '/task/:doc_id/edit', (->
        @layout 'layout'
        @render 'task_edit'
        ), name:'task_edit'
    Router.route '/task/:doc_id', (->
        @layout 'layout'
        @render 'task_view'
        ), name:'task_view'
    
    
    # Template.tasks.onCreated ->
    #     @autorun => Meteor.subscribe 'model_docs', 'task', ->
    Template.tasks.onCreated ->
        Session.setDefault 'view_mode', 'list'
        Session.setDefault 'sort_key', '_timestamp'
        Session.setDefault 'sort_label', 'available'
        Session.setDefault 'limit', 20

    Template.tasks.onCreated ->
        @autorun => @subscribe 'task_facets',
            picked_tags.array()

        @autorun => @subscribe 'task_results',
            picked_tags.array()
            Session.get('group_title_search')
            Session.get('limit')
            Session.get('sort_key')
            Session.get('sort_direction')

    Template.task_view.onCreated ->
        @autorun => Meteor.subscribe 'doc_by_id', Router.current().params.doc_id, ->
    Template.task_edit.onCreated ->
        @autorun => Meteor.subscribe 'doc_by_id', Router.current().params.doc_id, ->
    Template.task_card.onCreated ->
        # @autorun => Meteor.subscribe 'doc_comments', @data._id, ->


    Template.tasks.helpers
        task_docs: ->
            Docs.find 
                model:'task'
    Template.tasks.events
        'click .add_task': ->
            new_id = 
                Docs.insert 
                    model:'task'
            Router.go "/task/#{new_id}/edit"
    Template.task_card.events
        'click .view_task': ->
            Router.go "/task/#{@_id}"
    
    Template.task_edit.events
        'click .delete_task': ->
            Swal.fire({
                title: "delete task?"
                text: "cannot be undone"
                icon: 'question'
                confirmButtonText: 'delete'
                confirmButtonColor: 'red'
                showCancelButton: true
                cancelButtonText: 'cancel'
                reverseButtons: true
            }).then((result)=>
                if result.value
                    Docs.remove @_id
                    Swal.fire(
                        position: 'top-end',
                        icon: 'success',
                        title: 'task removed',
                        showConfirmButton: false,
                        timer: 1500
                    )
                    Router.go "/tasks"
            )

if Meteor.isServer
    Meteor.publish 'task_results', (
        )->
        # console.log picked_ingredients
        # if doc_limit
        #     limit = doc_limit
        # else
        limit = 42
        # if doc_sort_key
        #     sort_key = doc_sort_key
        # if doc_sort_direction
        #     sort_direction = parseInt(doc_sort_direction)
        self = @
        match = {model:'task'}
        sort = '_timestamp'
        if task_query and task_query.length > 1
            match.title = {$regex:"#{task_query}", $options: 'i'}
        # match.tags = $all: picked_ingredients
        # if filter then match.model = filter
        # keys = _.keys(prematch)
        # for key in keys
        #     key_array = prematch["#{key}"]
        #     if key_array and key_array.length > 0
        #         match["#{key}"] = $all: key_array
            # console.log 'current facet filter array', current_facet_filter_array

        # console.log 'task match', match
        # console.log 'sort key', sort_key
        # console.log 'sort direction', sort_direction
        Docs.find match,
            # sort:"#{sort_key}":sort_direction
            # sort:_timestamp:-1
            limit: 42
            
            
    Meteor.publish 'task_count', (
        picked_ingredients
        picked_sections
        task_query
        view_complete=false
        )->
        # @unblock()
    
        # console.log picked_ingredients
        self = @
        match = {model:'task'}
        sort = '_timestamp'
        if view_complete
            match.complete = true
        if task_query and task_query.length > 1
            console.log 'searching task_query', task_query
            match.title = {$regex:"#{task_query}", $options: 'i'}
        Counts.publish this, 'task_counter', Docs.find(match)
        return undefined

    Meteor.publish 'task_facets', (
        picked_tags=[]
        task_query
        )->
        # console.log 'dummy', dummy
        # console.log 'query', query

        self = @
        match = {}
        match.model = 'task'
            # match.$regex:"#{task_query}", $options: 'i'}
        if task_query and task_query.length > 1
            console.log 'searching task_query', task_query
            match.title = {$regex:"#{task_query}", $options: 'i'}
        tag_cloud = Docs.aggregate [
            { $match: match }
            { $project: "tags": 1 }
            { $unwind: "$tags" }
            { $group: _id: "$tags", count: $sum: 1 }
            { $match: _id: $nin: picked_tags }
            { $match: _id: {$regex:"#{query}", $options: 'i'} }
            { $sort: count: -1, _id: 1 }
            { $limit: 10 }
            { $project: _id: 0, name: '$_id', count: 1 }
            ]

        self.ready()