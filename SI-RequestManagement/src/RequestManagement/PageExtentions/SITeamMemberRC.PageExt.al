pageextension 52034 "SI Team Member RC" extends "Team Member Role Center"
{
    layout
    {
        addfirst(RoleCenter)
        {
            part(SIRequesterNotificationCues; "SI Requester Notification Cues")
            {
                ApplicationArea = All;
            }

            part(SIMyApprovals; "SI My Approvals Cues")
            {
                ApplicationArea = All;
            }
        }
    }
}