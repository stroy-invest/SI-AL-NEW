controladdin SIConstructionSitesGrid
{
    RequestedHeight = 150;
    MinimumHeight = 76;
    MaximumHeight = 190;
    RequestedWidth = 900;
    MinimumWidth = 500;
    HorizontalStretch = true;
    VerticalStretch = false;
    VerticalShrink = true;

    Scripts = 'src/UI/ControlAddIns/SIConstructionSitesGrid/SIConstructionSitesGrid.js';
    StartupScript = 'src/UI/ControlAddIns/SIConstructionSitesGrid/SIConstructionSitesGridStartup.js';
    StyleSheets = 'src/UI/ControlAddIns/SIConstructionSitesGrid/SIConstructionSitesGrid.css';

    event ControlReady();
    event AddSite();
    event OpenSite(SiteCode: Text);
    event ToggleShowAll(ShowAll: Boolean);
    event SetDefaultSite(SiteCode: Text);
    event FreezeSite(SiteCode: Text);
    event RestoreSite(SiteCode: Text);
    event AnnulateSite(SiteCode: Text);

    procedure SetSites(Data: Text; ShowingAll: Boolean);
}
