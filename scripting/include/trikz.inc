/** Double-include prevention */
#if defined _trikz_included_
  #endinput
#endif
#define _trikz_included_

/**
 *
 * Get the client's trikz partner
 *
 * @params client        An interger.
 * return                The partner of the client, An interger.
 */
native int T_GetClientPartner(int client);

/** 
 * 
 * Get the client's current autoflash option
 *
 * 
 * @params client       An interger.
 * return               The current autoflash option, bool.
 */
native bool T_GetClientAutoflash(int client);

/**
 *
 * Get the client's current autoswitch
 *
 * @params client        An interger.
 * return                The current autoswitch option, bool.
 */
native bool T_GetClientAutoswitch(int client);

/** 
 * 
 * Get the client's current block option
 *
 * 
 * @params client       An interger.
 * return               The current block option, bool.
 */
native bool T_GetClientBlock(int client);

/** 
 * 
 * Check if the player saved a checkpoint
 *
 * 
 * @params client       An interger.
 * @params cpnumber     An interger.
 * return               True if he did, false if he didn't, bool.
 */
native bool T_GetClientBCheckpoint(int client, int cpnumber);

/** 
 * 
 * Get the client's checkpoint
 *
 * 
 * @params client       An interger.
 * @params cpnumber     An interger.
 * return               The current checkpoint with the origin, velocity, angles, float.
 */
native float T_GetClientCheckpoint(int client, int cpnumber);

forward Action T_OnAutoswitch(int client);

forward Action T_OnAutoflash(int client);

forward Action T_OnBlock(int client);

forward Action T_OnCheckpointSave(int client, int cpnumber);

forward Action T_OnCheckpointLoad(int client, int cpnumber);

forward Action T_OnPartner(int client, int partner);

forward Action T_OnTeleport(int client, int teleport);

forward Action T_OnUnpartner(int client, int unparter);

forward Action T_OnAutoswitchPost(int client);

forward Action T_OnAutoflashPost(int client);

forward Action T_OnBlockPost(int client);

forward Action T_OnCheckpointSavePost(int client, int cpnumber);

forward Action T_OnCheckpointLoadPost(int client, int cpnumber);

forward Action T_OnPartnerPost(int client, int partner);

forward Action T_OnTeleportPost(int client, int teleport);

forward Action T_OnUnpartnerPost(int client, int unparter);


