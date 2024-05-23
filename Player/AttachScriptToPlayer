

# By Lil Wikipedia https://my.bio/lilwikipedia
#      _     _                              
#   \_|_) o | |                             
#     |     | |                             
#    _|   | |/                              
#   (/\___|_|__/   _                        
#   (_|   |   |_o | | o           | o       
#     |   |   |   | |     _  _  __|    __,  
#     |   |   | | |/_)| |/ \|/ /  | | /  |  
#      \_/ \_/  |_| \_|_|__/|__\_/|_|_\_/|_/
#                      /|                   
#                      \|  

my_device := class(creative_device):
    
    var Players : []player = array{}  
    @editable
    Button : button_device = button_device{}

    OnBegin<override>()<suspends>:void=
        set Players = GetPlayspace().GetPlayers()

        # Can replace button with any listenable device to initiate
        Button.InteractedWithEvent.Subscribe(AttachA)
            Print("Debug.ScriptInitializingPlayer1...")
    AttachA( Agent : agent) :void =
        if ( Fort1 := Agent.GetFortCharacter[]):
            Print("Debug.AttachingScriptToPlayer1...")
            
            spawn:
                AnyFunction(Fort1, Add arguments to pass if needed)
