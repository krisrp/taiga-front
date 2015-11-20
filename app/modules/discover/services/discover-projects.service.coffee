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
# File: discover-projects.service.coffee
###

taiga = @.taiga

class DiscoverProjectsService extends taiga.Service
    @.$inject = ["tgResources"]

    constructor: (@rs) ->
        @._mostLiked = Immutable.List()

        taiga.defineImmutableProperty @, "mostLiked", () => return @._mostLiked
        taiga.defineImmutableProperty @, "mostActive", () => return @._mostActive
        taiga.defineImmutableProperty @, "featured", () => return @._featured

    fetchMostLiked: () ->
        return @rs.projects.getProjects()
            .then (projects) => @._mostLiked = projects

    fetchMostActive: () ->
        return @rs.projects.getProjects()
            .then (projects) => @._mostActive = projects

    fetchFeatured: () ->
        return @rs.projects.getProjects()
            .then (projects) => @._featured = projects

angular.module("taigaDiscover").service("tgDiscoverProjectsService", DiscoverProjectsService)
