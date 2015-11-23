###
# Copyright (C) 2014-2015 Taiga Agile LLC <taiga@taiga.io>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#
# File: discover-search.controller.coffee
###

class DiscoverSearchController
    @.$inject = [
        '$routeParams',
        'tgDiscoverProjectsService'
    ]

    constructor: (@routeParams, @discoverProjectsService) ->
        @.page = 0
        @.likeOrder = null
        @.activityOrder = null

        taiga.defineImmutableProperty @, "searchResult", () => return @discoverProjectsService.searchResult

        @.q = @routeParams.text
        @.filter = @routeParams.filter || 'all'

        @.fetch()

    fetch: () ->
        return if @.loading

        @discoverProjectsService.resetSearchList()

        @.loading = true
        @.page = 0

        return @.search().then () =>
            @.loading = false

    showMore: () ->
        return if @.loading

        @.loading = true

        return @.search().then () =>
            @.loading = false
            @.page++

    search: () ->
        return @discoverProjectsService.fetchSearch({
            search: @.search,
            page: @.page,
            filter: @.filter,
            likeOrder: @.likeOrder,
            activityOrder: @.activityOrder
        })

    onChangeFilter: () ->
        @.fetch()

    onChangeOrder: () ->
        @.fetch()

angular.module("taigaDiscover").controller("DiscoverSearch", DiscoverSearchController)
