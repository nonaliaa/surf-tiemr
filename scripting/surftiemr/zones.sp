#include <textparse>
#include <sdktools>
#include <sourcemod>
#include <files>

/*public Action Zones(int client, int args)
{
    
    
    file f = OpenFile("surf_freedom.txt", "r", false);
    if(f == null)
        return ;

    fnction(client, f);
    return ;
}

public void fnction(int client, File handle ){

    char deez[32];
while(handle.ReadLine(deez, sizeof(deez))) 
{ 
int len = strlen(deez); 
if (deez[len-1] == '\n') 
    deez[--len] = '\0'; 

PrintToChat(client, "%s", deez); 

if(IsEndOfFile(handle)) 
    break; 
}
}*/
    
public Action PostFileContent(int client, int args)
{
    Handle fileh = OpenFile("addons\\sourcemod\\configs\\surftiemr_zones\\surf_freedom.txt", "r");
    if(fileh == INVALID_HANDLE)
    {
        PrintToServer("Invalid Handle for reading file: yourfilepath");
        return Plugin_Handled;
    }
 
    char buffer[1024];
    int len;
 
    while (ReadFileLine(fileh, buffer, sizeof(buffer)))
    {
        len = strlen(buffer);
        if (buffer[len-1] == '\n')
            buffer[--len] = '\0';
 
        PrintToChat(client, "%s", buffer);
 
        if(IsEndOfFile(fileh))
            break;
    }
    if(fileh != INVALID_HANDLE)
    {
        CloseHandle(fileh);
    }
    return Plugin_Handled;
}