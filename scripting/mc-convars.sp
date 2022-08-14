ConVar g_sChatPrefix;

void ConVars_Create(){
    AutoExecConfig_SetCreateDirectory(true);
    AutoExecConfig_SetCreateFile(true);
    AutoExecConfig_SetFile("mapchallenge");
    
    g_sChatPrefix = AutoExecConfig_CreateConVar("mc_chat_prefix", "{blue}Map Challenge {default}|", "Chat messages prefix");
    
    AutoExecConfig_ExecuteFile();
    AutoExecConfig_CleanFile();
}