codeunit 60018 "SI Project Repair Runner"
{
    TableNo = Job;

    trigger OnRun()
    var
        ProjectMgt: Codeunit "SI Construction Project Mgt.";
    begin
        ProjectMgt.RepairProject(Rec);
    end;
}
