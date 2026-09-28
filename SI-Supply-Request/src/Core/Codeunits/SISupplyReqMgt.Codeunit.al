codeunit 61001 "SI Supply Req Mgt."
{
    procedure CreateForProject(Project: Record Job; var Header: Record "SI Supply Req Header")
    begin
        Project.TestField("No.");
        Project.TestField("Location Code");

        Header.Init();
        Header.Validate("Project No.", Project."No.");
        Header."Request Date" := Today();
        Header.Insert(true);
    end;
}
