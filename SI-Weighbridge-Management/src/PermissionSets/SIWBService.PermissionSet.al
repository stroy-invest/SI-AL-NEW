permissionset 59154 "SI WB SERVICE"
{
    Assignable = true;
    Caption = 'SI Weighbridge - Service Access';

    Permissions =
        // Weighing records are created by inbound processing
        tabledata "SI Weighing Record" = RIM,
        table "SI Weighing Record" = X,

        // Operational documents are created automatically
        tabledata "SI Weighbridge Document" = RIM,
        table "SI Weighbridge Document" = X,

        tabledata "SI Weighbridge Document Line" = RIM,
        table "SI Weighbridge Document Line" = X,

        // Document creation queue is owned by background processing
        tabledata "SI WB Document Creation Queue" = RIMD,
        table "SI WB Document Creation Queue" = X,

        // Supporting/reference data
        tabledata "SI WB Supporting Document" = RIM,
        table "SI WB Supporting Document" = X,

        tabledata "SI WB Document Setup" = R,
        table "SI WB Document Setup" = X,

        tabledata "SI WB Posting Template" = R,
        table "SI WB Posting Template" = X,

        tabledata "SI WB Receipt Location Rule" = R,
        table "SI WB Receipt Location Rule" = X,

        // Background processing
        codeunit "SI WB Inbound Processor" = X,
        codeunit "SI WB Inbound Worker" = X,
        codeunit "SI WB Inbound Job" = X,

        codeunit "SI WB Document Creation Job" = X,
        codeunit "SI WB Document Creator" = X,
        codeunit "SI WB Document Factory" = X,

        codeunit "SI WB Document Mgt." = X,
        codeunit "SI WB UoM Conversion Mgt." = X,
        codeunit "SI WB Supporting Docs Mgt." = X,
        codeunit "SI WB Document Generation Mgt." = X,

        codeunit "SI WB Posting Templ. Resolver" = X,
        codeunit "SI WB Posting Templ. Applier" = X;
}