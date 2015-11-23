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
# File: discover-search.directive.coffee
###

DiscoverSearchBarDirective = (navUrls, location, route, routeParams) ->
    link = (scope, el, attrs, ctrl) ->
        submit = (event) =>
            event.preventDefault()

            text = el.find('input').val()
            url = navUrls.resolve('discover-search')

            scope.$apply -> location.search('text', text).path(url)

        el.on('submit', 'form', submit)

        attrs.$observe 'filter', () ->
            scope.vm.filter = scope.$eval(attrs.filter)

    return {
        controller: "DiscoverSearchBar",
        controllerAs: "vm"
        templateUrl: 'discover/components/discover-search-bar/discover-search-bar.html',
        bindToController: true,
        scope: {
            q: "="
            filter: "=",
            onChange: "&"
        },
        link: link
    }

DiscoverSearchBarDirective.$inject = [
    "$tgNavUrls",
    "$tgLocation",
    "$route",
    "$routeParams"
]

angular.module('taigaDiscover').directive('tgDiscoverSearchBar', DiscoverSearchBarDirective)
