// P0 runtime test harness. Manual invocation only, Sandbox only.
// BUILD ONLY until explicit approval to publish to Sandbox.
page 50993 "SI EDS P0 Runtime Harness"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    Caption = 'EDS P0 Runtime Harness (Sandbox only)';
    SourceTable = "Integer";
    SourceTableTemporary = true;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            group(ProbeSettings)
            {
                Caption = 'Synthetic HTTP tests';
                field(TestEndpoint; TestEndpoint)
                {
                    ApplicationArea = All;
                    Caption = 'Test HTTPS endpoint';
                    Editable = false;
                    ToolTip = 'Fixed public test endpoint. Synthetic values only; no real credentials.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RunEncodingProbe)
            {
                ApplicationArea = All;
                Caption = 'Verify SecretText URL encoding (httpbin)';
                Image = TestReport;
                ToolTip = 'Sandbox only. Checks decoded query value and encoded URL representation in httpbin JSON response.';

                trigger OnAction()
                var
                    EnvironmentInformation: Codeunit "Environment Information";
                    EncodingProbe: Codeunit "SI EDS P0 Encoding Test";
                    RepresentationMatches: Boolean;
                begin
                    if not EnvironmentInformation.IsSandbox() then
                        Error('P0 runtime harness is restricted to Sandbox.');
                    if not Confirm('Send one synthetic encoding test to https://httpbin.org/get?', false) then
                        exit;
                    RepresentationMatches := EncodingProbe.RunDeterministicTest();
                    if RepresentationMatches then
                        Message('P0 decoded value: PASS. httpbin URL representation: MATCH.')
                    else
                        Message('P0 decoded value: PASS. httpbin URL representation: DIFFERENT (not a definitive encoding failure).');
                end;
            }

            action(RunTelemetryProbe)
            {
                ApplicationArea = All;
                Caption = 'Run synthetic HTTP telemetry probe';
                Image = TestReport;
                ToolTip = 'Sandbox only. Sends a fixed synthetic marker to httpbin; inspect telemetry separately.';

                trigger OnAction()
                var
                    EnvironmentInformation: Codeunit "Environment Information";
                    TelemetryProbe: Codeunit "SI EDS Telemetry Probe";
                begin
                    if not EnvironmentInformation.IsSandbox() then
                        Error('P0 runtime harness is restricted to Sandbox.');
                    if not Confirm('Send one synthetic telemetry request to https://httpbin.org/get?', false) then
                        exit;
                    TelemetryProbe.RunSyntheticQueryProbe();
                    Message('P0 synthetic HTTP request completed. Check RT0019 in Application Insights.');
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        TestEndpoint := 'https://httpbin.org/get';
    end;

    var
        TestEndpoint: Text[100];
}
