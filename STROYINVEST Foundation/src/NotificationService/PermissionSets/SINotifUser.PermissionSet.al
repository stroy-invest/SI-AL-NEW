permissionset 50280 "SI NOTIF USER"
{
    Assignable = true;
    Caption = 'SI Нотифікації: користувач';

    Permissions =
        // Непрямі права для виконання Notification Service
        // через codeunit-и з властивістю Permissions.
        tabledata "SI Business Event Definition" = r,
        tabledata "SI Recipient Group" = r,
        tabledata "SI Business Event Entry" = rim,
        tabledata "SI Notification Entry" = Rim,

        page "SI My Notifications" = X,

        // Execute для нового Renderer
        codeunit "SI Payload Renderer" = X,

        // Perm. Sets for Notif. Cues
        tabledata "SI Notification Cue" = RIM,
        table "SI Notification Cue" = X,
        page "SI Notification Cues" = X,

        // Публічний і внутрішній runtime pipeline.
        codeunit "SI Business Event Service" = X,
        codeunit "SI Notification Dispatcher" = X,
        codeunit "SI Notif. Fingerprint Mgt." = X,
        codeunit "SI Notif. Lifecycle Mgt." = X;
}