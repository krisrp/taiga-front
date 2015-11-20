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
# File: discover-home-order-by.controller.coffee
###

class DiscoverHomeOrderByController
    @.$inject = []

    constructor: () ->
        @.is_open = false
        @.type = 'week'

        #TODO: TRANSLATE
        @.texts = {
            week: 'this week',
            month: 'this month',
            year: 'this year',
            all: 'all time'
        }

    currentText: () ->
        return @.texts[@.type]

    toggleOpen: () ->
        @.is_open = !@.is_open

    orderBy: (type) ->
        @.type = type
        @.is_open = false

        @.onChange({type: type})

angular.module("taigaDiscover").controller("DiscoverHomeOrderBy", DiscoverHomeOrderByController)
