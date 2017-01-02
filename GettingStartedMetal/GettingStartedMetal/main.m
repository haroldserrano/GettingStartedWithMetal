//
//  main.m
//  GettingStartedMetal
//
//  Created by Harold Serrano on 12/24/16.
//  Copyright © 2016 Harold Serrano. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

void gltSetWorkingDirectory(const char *szArgv);

int main(int argc, char * argv[]) {
    
    gltSetWorkingDirectory(*argv);
    
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}


void gltSetWorkingDirectory(const char *szArgv)
{
#ifdef __APPLE__
    static char szParentDirectory[255];
    
    ///////////////////////////////////////////////////////////////////////////
    // Get the directory where the .exe resides
    char *c;
    strncpy( szParentDirectory, szArgv, sizeof(szParentDirectory) );
    szParentDirectory[254] = '\0'; // Make sure we are NULL terminated
    
    c = (char*) szParentDirectory;
    
    while (*c != '\0')     // go to end
        c++;
    
    while (*c != '/')      // back up to parent
        c--;
    
    *c++ = '\0';           // cut off last part (binary name)
    
    ///////////////////////////////////////////////////////////////////////////
    // Change to Resources directory. Any data files need to be placed there
    chdir(szParentDirectory);
#ifndef METALAPI
    chdir("../Resources");
#endif
#endif
}
