using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }

team_manager_pair := class<concrete>:
    @editable
    ClassAndTeamSelector: class_and_team_selector_device = class_and_team_selector_device{}
    @editable
    TeamSettingsDevice: team_settings_and_inventory_device = team_settings_and_inventory_device{}
