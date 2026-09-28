// Full access for Admin
permissionset 59150 "SI WB FULL ACCESS"
{
    Assignable = true;
    Caption = 'SI Weighbridge - Full Access';

    Permissions =
        tabledata "SI Weighing Record" = RIMD,
        table "SI Weighing Record" = X,

        tabledata "SI Weighbridge Document" = RIMD,
        table "SI Weighbridge Document" = X,

        tabledata "SI Weighbridge Document Line" = RIMD,
        table "SI Weighbridge Document Line" = X,

        tabledata "SI WB Document Creation Queue" = RIMD,
        table "SI WB Document Creation Queue" = X,

        tabledata "SI WB Supporting Document" = RIMD,
        table "SI WB Supporting Document" = X,

        tabledata "SI WB Document Setup" = RIMD,
        table "SI WB Document Setup" = X,

        tabledata "SI WB Posting Template" = RIMD,
        table "SI WB Posting Template" = X,

        tabledata "SI WB Receipt Location Rule" = RIMD,
        table "SI WB Receipt Location Rule" = X,

        page "SI Weighing Records" = X,
        page "SI Weighing Record Card" = X,
        page "SI WB Inbound Runner" = X,
        page "SI WB Plate Correction" = X,

        page "SI Weighbridge Documents" = X,
        page "SI Weighbridge Document Card" = X,
        page "SI Weighbridge Document Lines" = X,
        page "SI WB Supporting Docs FactBox" = X,
        page "SI WB ERP Document FactBox" = X,
        page "SI WB Audit FactBox" = X,
        page "SI WB Conversion Panel" = X,
        page "SI WB Supporting Documents" = X,
        page "SI WB Document Setup" = X,
        page "SI WB Posting Templates" = X,
        page "SI WB Posting Template Card" = X,
        page "SI WB Receipt Location Rules" = X,

        codeunit "SI WB Plate Mgt." = X,
        codeunit "SI WB Inbound Processor" = X,
        codeunit "SI WB Inbound Worker" = X,
        codeunit "SI WB Inbound Job" = X,
        codeunit "SI WB Document Creation Job" = X,
        codeunit "SI WB Document Creator" = X,
        codeunit "SI WB Document Mgt." = X,
        codeunit "SI WB UoM Conversion Mgt." = X,
        codeunit "SI WB Document Factory" = X,
        codeunit "SI WB Supporting Docs Mgt." = X,
        codeunit "SI WB Document Generation Mgt." = X,
        codeunit "SI WB Posting Templ. Resolver" = X,
        codeunit "SI WB Posting Templ. Applier" = X,
        codeunit "SI WB Test Data Cleanup" = X;
}
