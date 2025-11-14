#include <iostream>
#include <tchar.h>

#include <open62541/server.h>
#include <open62541/server_config_default.h>
#include <open62541/plugin/log_stdout.h>
#include <open62541/server_config_file_based.h>

#include <open62541/plugin/nodesetloader.h>

#include "common.h"

#pragma comment(lib, "open62541-embt")

int _tmain(int argc, _TCHAR* argv[])
{
    UA_ByteString json_config = UA_BYTESTRING_NULL;
    UA_StatusCode retval = UA_STATUSCODE_GOOD;

    if(argc >= 2) {
        /* Load server config */
        json_config = loadFile(argv[1]);
    } else {
        UA_LOG_FATAL(UA_Log_Stdout, UA_LOGCATEGORY_USERLAND,
                     "Missing argument. Argument are "
                     "<server-config.json5>");
        return EXIT_FAILURE;
    }

    /* Alternative API function */
//    UA_Server *server = UA_Server_new();
//    UA_ServerConfig *config = UA_Server_getConfig(server);
//    retval = UA_ServerConfig_setFromFile(config, json_config);
//    if(retval != UA_STATUSCODE_GOOD) {
//        UA_Server_delete(server);
//        return EXIT_FAILURE;
//    }

	UA_Server *server = UA_Server_newFromFile(json_config);

	// load the nodeset data
	for (int cnt = 2; cnt < argc; cnt++) {
		if (UA_StatusCode_isBad(UA_Server_loadNodeset(server, argv[cnt], NULL))) {
			printf("Nodeset %s could not be loaded, exit\n", argv[cnt]);
			return EXIT_FAILURE;
		}
	}

    retval = UA_Server_runUntilInterrupt(server);
    retval |= UA_Server_delete(server);

    /* clean up */
    UA_ByteString_clear(&json_config);

    return retval == UA_STATUSCODE_GOOD ? EXIT_SUCCESS : EXIT_FAILURE;

}
