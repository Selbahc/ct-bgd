class ContentTools.VideoAudioDialog extends ContentTools.DialogUI

    # A dialog to support inserting an audio or video file

    #
    # ContentTools.FILE_UPLOADER = externalfileuploader
    #
    # The external library should provide an `init(dialog)` method. This method
    # recieves the dialog widget and can then set up all required event bindings
    # to support image uploads.

    constructor: ()->
        super('Insert audio or video file')

        # If the dialog is populated, this is the URL of the file
        @_fileURL = null

        # If the dialog is populated, this is the type of the file
        @_fileType = null

        # The upload progress of the dialog (0-100)
        @_progress = 0

        # The initial state of the dialog
        @_state = 'empty'

        # If a file uploader factory is defined create a new uploader for the
        # dialog.
        if ContentTools.FILE_UPLOADER
            ContentTools.FILE_UPLOADER(this)

    # Read-only properties

    # Methods

    clear: () ->
        # Clear the current file
        if @_domFile
            @_domFile.parentNode.removeChild(@_domFile)
            @_domFile = null

        # Clear file attributes
        @_fileURL = null
        @_fileType = null

        # Set the dialog to empty
        @state('empty')

    mount: () ->
        # Mount the widget
        super()

        # Update dialog class
        ContentEdit.addCSSClass(@_domElement, 'ct-media-dialog')
        ContentEdit.addCSSClass(@_domElement, 'ct-media-dialog--empty')

        # Update view class
        ContentEdit.addCSSClass(@_domView, 'ct-media-dialog__view')

        # Add controls

        # File tools & progress bar
        domTools = @constructor.createDiv(
            ['ct-control-group', 'ct-control-group--left'])
        @_domControls.appendChild(domTools)

        # Progress bar
        domProgressBar = @constructor.createDiv(['ct-progress-bar'])
        domTools.appendChild(domProgressBar)

        @_domProgress = @constructor.createDiv(['ct-progress-bar__progress'])
        domProgressBar.appendChild(@_domProgress)

        # Actions
        domActions = @constructor.createDiv(
            ['ct-control-group', 'ct-control-group--right'])
        @_domControls.appendChild(domActions)

        # Upload button
        @_domUpload = @constructor.createDiv([
            'ct-control',
            'ct-control--text',
            'ct-control--upload'
            ])
        @_domUpload.textContent = ContentEdit._('Upload')
        domActions.appendChild(@_domUpload)

        # File input for upload
        @_domInput = document.createElement('input')
        @_domInput.setAttribute('class', 'ct-media-dialog__file-upload')
        @_domInput.setAttribute('name', 'file')
        @_domInput.setAttribute('type', 'file')
        @_domInput.setAttribute('accept', 'audio/mpeg,video/mp4')
        @_domUpload.appendChild(@_domInput)

        # Insert
        @_domInsert = @constructor.createDiv([
            'ct-control',
            'ct-control--text',
            'ct-control--insert'
            ])
        @_domInsert.textContent = ContentEdit._('Insert')
        domActions.appendChild(@_domInsert)

        # Cancel
        @_domCancelUpload = @constructor.createDiv([
            'ct-control',
            'ct-control--text',
            'ct-control--cancel'
            ])
        @_domCancelUpload.textContent = ContentEdit._('Cancel')
        domActions.appendChild(@_domCancelUpload)

        # Clear
        @_domClear = @constructor.createDiv([
            'ct-control',
            'ct-control--text',
            'ct-control--clear'
            ])
        @_domClear.textContent = ContentEdit._('Clear')
        domActions.appendChild(@_domClear)

        # Add interaction handlers
        @_addDOMEventListeners()

        @dispatchEvent(@createEvent('fileuploader.mount'))

    progress: (progress) ->
        # Get/Set upload progress
        if progress is undefined
            return @_progress

        @_progress = progress

        # Update progress bar width
        if not @isMounted()
            return

        @_domProgress.style.width = "#{ @_progress }%"

    save: (fileURL, fileType) ->
        # Save and insert the current image
        @dispatchEvent(
            @createEvent(
                'save',
                {
                    'fileURL': fileURL,
                    'fileType': fileType,
                })
            )

    state: (state) ->
        # Set/get the state of the dialog (empty, uploading, populated)

        if state is undefined
            return @_state

        # Check that we need to change the current state of the dialog
        if @_state == state
            return

        # Modify the state
        prevState = @_state
        @_state = state

        # Update state modifier class for the dialog
        if not @isMounted()
            return

        ContentEdit.addCSSClass(@_domElement, "ct-media-dialog--#{ @_state }")
        ContentEdit.removeCSSClass(
            @_domElement,
            "ct-media-dialog--#{ prevState }"
            )

    unmount: () ->
        # Unmount the component from the DOM
        super()

        @_domCancelUpload = null
        @_domClear = null
        @_domInput = null
        @_domInsert = null
        @_domProgress = null
        @_domUpload = null

        @dispatchEvent(@createEvent('fileuploader.unmount'))

    populate: (fileURL, fileType) ->
        # Preview the specified URL

        @_fileURL = fileURL
        @_fileType = fileType

        # Insert the video/audio in preview
        if @_fileType is 'video/mp4'
            @_domFile = document.createElement('video')
            @_domFile.setAttribute('height', '100%')
            @_domFile.setAttribute('src', @_fileURL)
            @_domFile.setAttribute('controls', '')
            @_domFile.setAttribute('width', '100%')
            @_domView.appendChild(@_domFile)
        if @_fileType is 'audio/mpeg'
            @_domFile = document.createElement('audio')
            @_domFile.setAttribute('src', @_fileURL)
            @_domFile.setAttribute('controls', '')
            @_domFile.setAttribute('style', 'width: 100%; height: 100%;')
            @_domView.appendChild(@_domFile)
        
        @state('populated')

    # Private methods

    _addDOMEventListeners: () ->
        # Add event listeners for the widget
        super()

        # File ready for upload
        @_domInput.addEventListener 'change', (ev) =>
            # Get the file uploaded
            file = ev.target.files[0]

            # Ignore empty file changes (this may occur when we change the
            # value of the input field to '', see issue:
            # https://github.com/GetmeUK/ContentTools/issues/385
            unless file
                return

            # Clear the file inputs value so that the same file can be uploaded
            # again if the user cancels the upload or clears it and starts then
            # changes their mind.
            ev.target.value = ''
            if ev.target.value
                # Hack for clearing the file field value in IE
                ev.target.type = 'text'
                ev.target.type = 'file'

            @dispatchEvent(
                @createEvent('fileuploader.fileready', {file: file})
                )

        # Cancel upload
        @_domCancelUpload.addEventListener 'click', (ev) =>
            @dispatchEvent(@createEvent('fileuploader.cancelupload'))

        # Clear image
        @_domClear.addEventListener 'click', (ev) =>
            @dispatchEvent(@createEvent('fileuploader.clear'))

        @_domInsert.addEventListener 'click', (ev) =>
            @dispatchEvent(@createEvent('fileuploader.save'))
