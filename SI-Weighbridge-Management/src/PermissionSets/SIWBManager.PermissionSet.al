permissionset 59152 "SI WB MANAGER"
{
    Assignable = true;
    Caption = 'SI Weighbridge - Manager Access';

    Permissions =
        // ---------------------------------------------------------
        // Weighing facts - read only
        // ---------------------------------------------------------
        tabledata "SI Weighing Record" = R,
        table "SI Weighing Record" = X,

        // ---------------------------------------------------------
        // Operational documents
        // ---------------------------------------------------------
        tabledata "SI Weighbridge Document" = RM,
        table "SI Weighbridge Document" = X,

        tabledata "SI Weighbridge Document Line" = RIM,
        table "SI Weighbridge Document Line" = X,

        // ---------------------------------------------------------
        // Supporting documents
        // ---------------------------------------------------------
        tabledata "SI WB Supporting Document" = RIMD,
        table "SI WB Supporting Document" = X,

        // ---------------------------------------------------------
        // Technical/reference data - read only
        // ---------------------------------------------------------
        tabledata "SI WB Document Creation Queue" = R,
        table "SI WB Document Creation Queue" = X,

        tabledata "SI WB Document Setup" = R,
        table "SI WB Document Setup" = X,

        tabledata "SI WB Posting Template" = R,
        table "SI WB Posting Template" = X,

        tabledata "SI WB Receipt Location Rule" = R,
        table "SI WB Receipt Location Rule" = X,

        // ---------------------------------------------------------
        // UI
        // ---------------------------------------------------------
        page "SI Weighing Records" = X,
        page "SI Weighing Record Card" = X,

        page "SI Weighbridge Documents" = X,
        page "SI Weighbridge Document Card" = X,
        page "SI Weighbridge Document Lines" = X,

        page "SI WB Supporting Docs FactBox" = X,
        page "SI WB ERP Document FactBox" = X,
        page "SI WB Audit FactBox" = X,
        page "SI WB Conversion Panel" = X,
        page "SI WB Supporting Documents" = X,

        // ---------------------------------------------------------
        // Business logic
        // ---------------------------------------------------------
        codeunit "SI WB Document Mgt." = X,
        codeunit "SI WB UoM Conversion Mgt." = X,
        codeunit "SI WB Supporting Docs Mgt." = X,
        codeunit "SI WB Document Generation Mgt." = X;
}