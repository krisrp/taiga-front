###
# Copyright (C) 2014-2016 Andrey Antukh <niwi@niwi.nz>
# Copyright (C) 2014-2016 Jesús Espino Garcia <jespinog@gmail.com>
# Copyright (C) 2014-2016 David Barragán Merino <bameda@dbarragan.com>
# Copyright (C) 2014-2016 Alejandro Alonso <alejandro.alonso@kaleidos.net>
# Copyright (C) 2014-2016 Juan Francisco Alcántara <juanfran.alcantara@kaleidos.net>
# Copyright (C) 2014-2016 Xavi Julian <xavier.julian@kaleidos.net>
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
# File: modules/base/contrib.coffee
###

module = angular.module("taigaBase")


class ContribController extends taiga.Controller
    @.$inject = [
        "$rootScope",
        "$scope",
        "$routeParams",
        "$tgRepo",
        "$tgResources",
        "$tgConfirm"
    ]

    constructor: (@rootScope, @scope, @params, @repo, @rs, @confirm) ->
        @scope.currentPlugin = _.head(_.filter(@rootScope.adminPlugins, {"slug": @params.plugin}))
        @scope.projectSlug = @params.pslug

        promise = @.loadInitialData()

        promise.then null, =>
            @confirm.notify("error")

    loadProject: ->
        return @rs.projects.getBySlug(@params.pslug).then (project) =>
            @scope.projectId = project.id
            @scope.project = project
            @scope.$emit('project:loaded', project)
            @scope.$broadcast('project:loaded', project)
            return project

    loadInitialData: ->
        return @.loadProject()

module.controller("ContribController", ContribController)
