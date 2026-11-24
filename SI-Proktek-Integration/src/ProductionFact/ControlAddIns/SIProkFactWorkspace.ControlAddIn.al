controladdin "SI Prok Fact Workspace"
{
    RequestedHeight = 560;
    MinimumHeight = 560;
    HorizontalStretch = true;
    VerticalStretch = false;
    VerticalShrink = false;
    Scripts = 'SIProkFactWorkspace.js';
    StartupScript = 'SIProkFactWorkspaceStartup.js';
    event Ready();
    procedure RenderFact(PayloadJson: Text);
}
