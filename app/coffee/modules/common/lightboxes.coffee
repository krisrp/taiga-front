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
# File: modules/common/lightboxes.coffee
###

module = angular.module("taigaCommon")

bindOnce = @.taiga.bindOnce
timeout = @.taiga.timeout
debounce = @.taiga.debounce
sizeFormat = @.taiga.sizeFormat

#############################################################################
## Common Lightbox Services
#############################################################################

# the lightboxContent hide/show doesn't have sense because is an IE hack
class LightboxService extends taiga.Service
    constructor: (@animationFrame, @q) ->

    open: ($el) ->
        defered = @q.defer()

        lightboxContent = $el.children().not(".close")
        lightboxContent.hide()

        @animationFrame.add ->
            $el.css('display', 'flex')

        @animationFrame.add ->
            $el.addClass("open")
            $el.one "transitionend", =>
              $el.find('input,textarea').first().focus()

        @animationFrame.add =>
            lightboxContent.show()
            defered.resolve()

        docEl = angular.element(document)
        docEl.on "keydown.lightbox", (e) =>
            code = if e.keyCode then e.keyCode else e.which
            @.close($el) if code == 27

        return defered.promise

    close: ($el) ->
        docEl = angular.element(document)
        docEl.off(".lightbox")
        docEl.off(".keyboard-navigation") # Hack: to fix problems in the WYSIWYG textareas when press ENTER
        $el.one "transitionend", =>
            $el.removeAttr('style')
            $el.removeClass("open").removeClass('close')

        $el.addClass('close')

        if $el.hasClass("remove-on-close")
            scope = $el.data("scope")
            scope.$destroy()
            $el.remove()

    closeAll: ->
        docEl = angular.element(document)
        for lightboxEl in docEl.find(".lightbox.open")
            @.close($(lightboxEl))


module.service("lightboxService", ["animationFrame", "$q", LightboxService])


class LightboxKeyboardNavigationService extends taiga.Service
    stop: ->
        docEl = angular.element(document)
        docEl.off(".keyboard-navigation")

    dispatch: ($el, code) ->
        activeElement = $el.find(".selected")

        # Key: enter
        if code == 13
            if $el.find(".user-list-single").length == 1
                $el.find('.user-list-single:first').trigger("click")
            else
                activeElement.trigger("click")

        # Key: down
        else if code == 40
            if not activeElement.length
                $el.find('.user-list-single:not(".is-active"):first').addClass('selected')
            else
                next = activeElement.next('.user-list-single')
                if next.length
                    activeElement.removeClass('selected')
                    next.addClass('selected')
        # Key: up
        else if code == 38
            if not activeElement.length
                $el.find('.user-list-single:last').addClass('selected')
            else
                prev = activeElement.prev('.user-list-single:not(".is-active")')

                if prev.length
                    activeElement.removeClass('selected')
                    prev.addClass('selected')

    init: ($el) ->
        @stop()
        docEl = angular.element(document)
        docEl.on "keydown.keyboard-navigation", (event) =>
            code = if event.keyCode then event.keyCode else event.which
            if code == 40 || code == 38 || code == 13
                event.preventDefault()
                @.dispatch($el, code)

module.service("lightboxKeyboardNavigationService", LightboxKeyboardNavigationService)


#############################################################################
## Generic Lighthbox Directive
#############################################################################

# This adds generic behavior to all blocks with lightbox class like
# close button event handlers.

LightboxDirective = (lightboxService) ->
    link = ($scope, $el, $attrs) ->
        $el.on "click", ".close", (event) ->
            event.preventDefault()
            lightboxService.close($el)

    return {restrict: "C", link: link}

module.directive("lightbox", ["lightboxService", LightboxDirective])

#############################################################################
## Block Lightbox Directive
#############################################################################

# Issue/Userstory blocking message lightbox directive.

BlockLightboxDirective = ($rootscope, $tgrepo, $confirm, lightboxService, $loading, $qqueue, $translate) ->
    link = ($scope, $el, $attrs, $model) ->
        title = $translate.instant($attrs.title)
        $el.find("h2.title").text(title)

        unblock = $qqueue.bindAdd (item, finishCallback) =>
            promise = $tgrepo.save(item)
            promise.then ->
                $confirm.notify("success")
                $rootscope.$broadcast("object:updated")
                $model.$setViewValue(item)
                finishCallback()

            promise.then null, ->
                $confirm.notify("error")
                item.revert()
                $model.$setViewValue(item)

            promise.finally ->
                finishCallback()

            return promise

        block = $qqueue.bindAdd (item) =>
            $model.$setViewValue(item)

            currentLoading = $loading()
                .target($el.find(".button-green"))
                .start()

            promise = $tgrepo.save($model.$modelValue)
            promise.then ->
                $confirm.notify("success")
                $rootscope.$broadcast("object:updated")

            promise.then null, ->
                $confirm.notify("error")
                item.revert()
                $model.$setViewValue(item)

            promise.finally ->
                currentLoading.finish()
                lightboxService.close($el)

        $scope.$on "block", ->
            $el.find(".reason").val($model.$modelValue.blocked_note)
            lightboxService.open($el)

        $scope.$on "unblock", (event, model, finishCallback) =>
            item = $model.$modelValue.clone()
            item.is_blocked = false
            item.blocked_note = ""

            unblock(item, finishCallback)

        $scope.$on "$destroy", ->
            $el.off()

        $el.on "click", ".button-green", (event) ->
            event.preventDefault()

            item = $model.$modelValue.clone()
            item.is_blocked = true
            item.blocked_note = $el.find(".reason").val()

            block(item)

    return {
        templateUrl: "common/lightbox/lightbox-block.html"
        link: link
        require: "ngModel"
    }

module.directive("tgLbBlock", ["$rootScope", "$tgRepo", "$tgConfirm", "lightboxService", "$tgLoading", "$tgQqueue", "$translate", BlockLightboxDirective])


#############################################################################
## Generic Lightbox Blocking-Message Input Directive
#############################################################################

BlockingMessageInputDirective = ($log, $template, $compile) ->
    template = $template.get("common/lightbox/lightbox-blocking-message-input.html", true)

    link = ($scope, $el, $attrs, $model) ->
        if not $attrs.watch
            return $log.error "No watch attribute on tg-blocking-message-input directive"

        $scope.$watch $attrs.watch, (value) ->
            if value is not undefined and value == true
                $el.find(".blocked-note").removeClass("hidden")
            else
                $el.find(".blocked-note").addClass("hidden")

    templateFn = ($el, $attrs) ->
        return template({ngmodel: $attrs.ngModel})

    return {
        template: templateFn
        link: link
        require: "ngModel"
        restrict: "EA"
    }

module.directive("tgBlockingMessageInput", ["$log", "$tgTemplate", "$compile", BlockingMessageInputDirective])


#############################################################################
## Create/Edit Userstory Lightbox Directive
#############################################################################

CreateEditUserstoryDirective = ($repo, $model, $rs, $rootScope, lightboxService, $loading, $translate, $confirm, $q, attachmentsService) ->
    link = ($scope, $el, attrs) ->
        form = null
        $scope.createEditUs = {}
        $scope.isNew = true

        attachmentsToAdd = Immutable.List()
        attachmentsToDelete = Immutable.List()

        resetAttachments = () ->
            attachmentsToAdd = Immutable.List()
            attachmentsToDelete = Immutable.List()

        $scope.addAttachment = (attachment) ->
            attachmentsToAdd = attachmentsToAdd.push(attachment)

        $scope.deleteAttachment = (attachment) ->
            attachmentsToDelete = attachmentsToDelete.push(attachment)

        $scope.$on "usform:new", (ctx, projectId, status, statusList) ->
            form.reset() if form
            $scope.isNew = true
            $scope.usStatusList = statusList
            $scope.attachments = Immutable.List()

            resetAttachments()

            $scope.us = $model.make_model("userstories", {
                project: projectId
                points : {}
                status: status
                is_archived: false
                tags: []
            })

            # Update texts for creation
            $el.find(".button-green").html($translate.instant("COMMON.CREATE"))
            $el.find(".title").html($translate.instant("LIGHTBOX.CREATE_EDIT_US.NEW_US"))
            $el.find(".tag-input").val("")

            $el.find(".blocked-note").addClass("hidden")
            $el.find("label.blocked").removeClass("selected")
            $el.find("label.team-requirement").removeClass("selected")
            $el.find("label.client-requirement").removeClass("selected")

            lightboxService.open($el)

        $scope.$on "usform:edit", (ctx, us, attachments) ->
            form.reset() if form

            $scope.us = us
            $scope.attachments = Immutable.fromJS(attachments)
            $scope.isNew = false

            resetAttachments()

            # Update texts for edition
            $el.find(".button-green").html($translate.instant("COMMON.SAVE"))
            $el.find(".title").html($translate.instant("LIGHTBOX.CREATE_EDIT_US.EDIT_US"))
            $el.find(".tag-input").val("")

            # Update requirement info (team, client or blocked)
            if us.is_blocked
                $el.find(".blocked-note").removeClass("hidden")
                $el.find("label.blocked").addClass("selected")
            else
                $el.find(".blocked-note").addClass("hidden")
                $el.find("label.blocked").removeClass("selected")

            if us.team_requirement
                $el.find("label.team-requirement").addClass("selected")
            else
                $el.find("label.team-requirement").removeClass("selected")
            if us.client_requirement
                $el.find("label.client-requirement").addClass("selected")
            else
                $el.find("label.client-requirement").removeClass("selected")

            lightboxService.open($el)

        createAttachments = (obj) ->
            promises = _.map attachmentsToAdd.toJS(), (attachment) ->
                attachmentsService.upload(attachment.file, obj.id, $scope.us.project, 'us')

            return $q.all(promises)

        deleteAttachments = (obj) ->
            promises = _.map attachmentsToDelete.toJS(), (attachment) ->
                return attachmentsService.delete("us", attachment.id)

            return $q.all(promises)

        submit = debounce 2000, (event) =>
            event.preventDefault()

            form = $el.find("form").checksley()
            if not form.validate()
                return

            currentLoading = $loading()
                .target(submitButton)
                .start()

            if $scope.isNew
                promise = $repo.create("userstories", $scope.us)
                broadcastEvent = "usform:new:success"
            else
                promise = $repo.save($scope.us)
                broadcastEvent = "usform:edit:success"

            promise.then (data) ->
                deleteAttachments(data).then () =>  createAttachments(data)

                return data

            promise.then (data) ->
                currentLoading.finish()
                lightboxService.close($el)
                $rootScope.$broadcast(broadcastEvent, data)

            promise.then null, (data) ->
                currentLoading.finish()
                form.setErrors(data)
                if data._error_message
                    $confirm.notify("error", data._error_message)

        submitButton = $el.find(".submit-button")

        $el.on "submit", "form", submit

        $el.on "click", ".close", (event) ->
            event.preventDefault()
            $scope.$apply ->
                $scope.us.revert()
            lightboxService.close($el)

        $el.keydown (event) ->
            code = if event.keyCode then event.keyCode else event.which
            if code == 27
                lightboxService.close($el)
                $scope.$apply ->
                    $scope.us.revert()

        $scope.$on "$destroy", ->
            $el.off()

    return {link: link}

module.directive("tgLbCreateEditUserstory", [
    "$tgRepo",
    "$tgModel",
    "$tgResources",
    "$rootScope",
    "lightboxService",
    "$tgLoading",
    "$translate",
    "$tgConfirm",
    "$q",
    "tgAttachmentsService",
    CreateEditUserstoryDirective
])


#############################################################################
## Creare Bulk Userstories Lightbox Directive
#############################################################################

CreateBulkUserstoriesDirective = ($repo, $rs, $rootscope, lightboxService, $loading) ->
    link = ($scope, $el, attrs) ->
        form = null

        $scope.$on "usform:bulk", (ctx, projectId, status) ->
            form.reset() if form

            $scope.new = {
                projectId: projectId
                statusId: status
                bulk: ""
            }
            lightboxService.open($el)

        submit = debounce 2000, (event) =>
            event.preventDefault()

            form = $el.find("form").checksley({onlyOneErrorElement: true})
            if not form.validate()
                return

            currentLoading = $loading()
                .target(submitButton)
                .start()

            promise = $rs.userstories.bulkCreate($scope.new.projectId, $scope.new.statusId, $scope.new.bulk)
            promise.then (result) ->
                currentLoading.finish()
                $rootscope.$broadcast("usform:bulk:success", result)
                lightboxService.close($el)

            promise.then null, (data) ->
                currentLoading.finish()
                form.setErrors(data)
                if data._error_message
                    $confirm.notify("error", data._error_message)

        submitButton = $el.find(".submit-button")

        $el.on "submit", "form", submit

        $scope.$on "$destroy", ->
            $el.off()

    return {link: link}

module.directive("tgLbCreateBulkUserstories", [
    "$tgRepo",
    "$tgResources",
    "$rootScope",
    "lightboxService",
    "$tgLoading",
    CreateBulkUserstoriesDirective
])


#############################################################################
## AssignedTo Lightbox Directive
#############################################################################

AssignedToLightboxDirective = (lightboxService, lightboxKeyboardNavigationService, $template, $compile) ->
    link = ($scope, $el, $attrs) ->
        selectedUser = null
        selectedItem = null
        usersTemplate = $template.get("common/lightbox/lightbox-assigned-to-users.html", true)

        normalizeString = (string) ->
            normalizedString = string
            normalizedString = normalizedString.replace("Á", "A").replace("Ä", "A").replace("À", "A")
            normalizedString = normalizedString.replace("É", "E").replace("Ë", "E").replace("È", "E")
            normalizedString = normalizedString.replace("Í", "I").replace("Ï", "I").replace("Ì", "I")
            normalizedString = normalizedString.replace("Ó", "O").replace("Ö", "O").replace("Ò", "O")
            normalizedString = normalizedString.replace("Ú", "U").replace("Ü", "U").replace("Ù", "U")
            return normalizedString

        filterUsers = (text, user) ->
            username = user.full_name_display.toUpperCase()
            username = normalizeString(username)
            text = text.toUpperCase()
            text = normalizeString(text)
            return _.includes(username, text)

        render = (selected, text) ->
            users = _.clone($scope.activeUsers, true)
            users = _.reject(users, {"id": selected.id}) if selected?
            users = _.filter(users, _.partial(filterUsers, text)) if text?

            ctx = {
                selected: selected
                users: _.slice(users, 0, 5)
                showMore: users.length > 5
            }

            html = usersTemplate(ctx)
            html = $compile(html)($scope)

            $el.find(".assigned-to-list").html(html)

        closeLightbox = () ->
            lightboxKeyboardNavigationService.stop()
            lightboxService.close($el)

        $scope.$on "assigned-to:add", (ctx, item) ->
            selectedItem = item
            assignedToId = item.assigned_to
            selectedUser = $scope.usersById[assignedToId]

            render(selectedUser)
            lightboxService.open($el).then ->
                $el.find('input').focus()
                lightboxKeyboardNavigationService.init($el)

        $scope.$watch "usersSearch", (searchingText) ->
            if searchingText?
                render(selectedUser, searchingText)
                $el.find('input').focus()

        $el.on "click", ".user-list-single", (event) ->
            event.preventDefault()
            target = angular.element(event.currentTarget)

            closeLightbox()

            $scope.$apply ->
                $scope.$broadcast("assigned-to:added", target.data("user-id"), selectedItem)
                $scope.usersSearch = null

        $el.on "click", ".remove-assigned-to", (event) ->
            event.preventDefault()
            event.stopPropagation()

            closeLightbox()

            $scope.$apply ->
                $scope.usersSearch = null
                $scope.$broadcast("assigned-to:added", null, selectedItem)

        $el.on "click", ".close", (event) ->
            event.preventDefault()

            closeLightbox()

            $scope.$apply ->
                $scope.usersSearch = null

        $scope.$on "$destroy", ->
            $el.off()

    return {
        templateUrl: "common/lightbox/lightbox-assigned-to.html"
        link:link
    }


module.directive("tgLbAssignedto", ["lightboxService", "lightboxKeyboardNavigationService", "$tgTemplate", "$compile", AssignedToLightboxDirective])


#############################################################################
## Watchers Lightbox directive
#############################################################################

WatchersLightboxDirective = ($repo, lightboxService, lightboxKeyboardNavigationService, $template, $compile) ->
    link = ($scope, $el, $attrs) ->
        selectedItem = null
        usersTemplate = $template.get("common/lightbox/lightbox-assigned-to-users.html", true)

        # Get prefiltered users by text
        # and without now watched users.
        getFilteredUsers = (text="") ->
            _filterUsers = (text, user) ->
                if selectedItem && _.find(selectedItem.watchers, (x) -> x == user.id)
                    return false

                username = user.full_name_display.toUpperCase()
                text = text.toUpperCase()
                return _.includes(username, text)

            users = _.clone($scope.activeUsers, true)
            users = _.filter(users, _.partial(_filterUsers, text))
            return users

        # Render the specific list of users.
        render = (users) ->
            ctx = {
                selected: false
                users: _.head(users, 5)
                showMore: users.length > 5
            }

            html = usersTemplate(ctx)
            html = $compile(html)($scope)
            $el.find(".ticket-watchers").html(html)

        closeLightbox = () ->
            lightboxKeyboardNavigationService.stop()
            lightboxService.close($el)

        $scope.$on "watcher:add", (ctx, item) ->
            selectedItem = item

            users = getFilteredUsers()
            render(users)

            lightboxService.open($el).then ->
                $el.find("input").focus()
                lightboxKeyboardNavigationService.init($el)

        $scope.$watch "usersSearch", (searchingText) ->
            if not searchingText?
                return

            users = getFilteredUsers(searchingText)
            render(users)
            $el.find("input").focus()

        $el.on "click", ".user-list-single", debounce 2000, (event) ->
            closeLightbox()

            event.preventDefault()
            target = angular.element(event.currentTarget)

            $scope.$apply ->
                $scope.usersSearch = null
                $scope.$broadcast("watcher:added", target.data("user-id"))

        $el.on "click", ".close", (event) ->
            event.preventDefault()

            closeLightbox()

            $scope.$apply ->
                $scope.usersSearch = null

        $scope.$on "$destroy", ->
            $el.off()

    return {
        templateUrl: "common/lightbox/lightbox-users.html"
        link:link
    }

module.directive("tgLbWatchers", ["$tgRepo", "lightboxService", "lightboxKeyboardNavigationService", "$tgTemplate", "$compile", WatchersLightboxDirective])


#############################################################################
## Attachment Preview Lighbox
#############################################################################

AttachmentPreviewLightboxDirective = (lightboxService, $template, $compile) ->
    link = ($scope, $el, attrs) ->
        lightboxService.open($el)

    return {
        templateUrl: 'common/lightbox/lightbox-attachment-preview.html',
        link: link,
        scope: true
    }

module.directive("tgLbAttachmentPreview", ["lightboxService", "$tgTemplate", "$compile", AttachmentPreviewLightboxDirective])
