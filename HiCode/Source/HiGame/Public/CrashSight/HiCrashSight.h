// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#if PLATFORM_WINDOWS
#include "Windows/AllowWindowsPlatformTypes.h"
#include "Windows/PreWindowsApi.h"
#include <windows.h>
#include "Windows/PostWindowsApi.h"
#include "Windows/HideWindowsPlatformTypes.h"
#include <cstdio>
#include <iostream>
#include <memory>
#include <stdexcept>
#include <string>
#include <array>
#include <fstream>
#endif

#include "Containers/Deque.h"
#include "CoreMinimal.h"
#include "Misc/Paths.h"
#include "Misc/FileHelper.h"
#include "Logging/LogMacros.h"
#include "Kismet/BlueprintFunctionLibrary.h"
#include "HiCrashSight.generated.h"


#if PLATFORM_WINDOWS
typedef void(*SetTQMConfig)(const char* id, const char* version, const char* key);
typedef void(*reportException)(int type, const char* name, const char* message, const char* stackTrace, const char * extras);
typedef void(*CrashCallbackFuncPtr)(int type, const char* guid);
typedef void(*SetCrashCallback)(CrashCallbackFuncPtr callback);
typedef void (*CsReportCrash)();
enum LogSeverity {
  Log,
  LogDebug,
  LogInfo,
  LogWarning,
  LogAssert,
  LogError,
  LogException
};
typedef void(*PrintLog)(LogSeverity level, const char* tag, const char *format, ...);
typedef void(*SetUserValue)(const char* key, const char* value);
typedef void (*SetVehEnable)(bool enable);
typedef void (*SetExtraHandler)(bool extra_handle_enable);
typedef bool (*MonitorEnable)(bool enable);
typedef void (*CsReportCrash)();
typedef int (*SetCustomLogDir)(const char* log_path);
typedef void (*CS_UnrealCriticalErrorEnable)(bool enable);
typedef void (*CS_AddValidExpCode)(unsigned long exp_code);
#endif

/**
 * 
 */
UCLASS()
class HIGAME_API UHiCrashSight : public UBlueprintFunctionLibrary
{
	GENERATED_BODY()

public:	
	UHiCrashSight();
	~UHiCrashSight();

	UFUNCTION(BlueprintCallable, Category = HiCrashSight)
	static void SetTQMConfigHi(const FString& UserID, const FString& Version, const FString& LogVersion, const FString& Key);

	UFUNCTION(BlueprintCallable, Category = HiCrashSight)
	static void ReportExceptionHi(const FString& ExpName, const FString& ExpMessage, const FString& StackTrace, const FString& Extras);

	UFUNCTION(BlueprintCallable, Category = HiCrashSight)
	static void GenCrash();

	UFUNCTION(BlueprintCallable, Category = HiCrashSight)
	static void SetUserValueHi(const FString& Key, const FString& Value);

	UFUNCTION(BlueprintCallable, Category = HiCrashSight)
	static void CsReportCrashHi();

	UFUNCTION(BlueprintCallable, Category = HiCrashSight)
	static int SetCustomLogDirHi(const FString& LPath);

#if PLATFORM_WINDOWS
	static void SetCrashCallbackHi(CrashCallbackFuncPtr callback);
	static void PrintLogHi(LogSeverity level, const char* tag, const char *format, ...);
#endif
	static void SetVehEnableHi(bool enable);
	static void SetExtraHandlerHi(bool extra_handle_enable);
	static void MonitorEnableHi(bool enable);
	static void CS_UnrealCriticalErrorEnableHi(bool enable);
	static void CS_AddValidExpCodeHi(unsigned long exp_code);

private:
#if PLATFORM_WINDOWS
	inline static HINSTANCE dllHandler = nullptr;
	inline static FString WinVersion = FString("1.0.0");
	inline static bool bTest = false;
#endif
	FDelegateHandle OnHandleSystemErrorHandle;
	FDelegateHandle OnHandleSystemEnsureHandle;
	FDelegateHandle ViewportCreatedHandle;

	// Lua Trace
	inline static TDeque<FString> CrashLuaTraces;

private:
	static void InitDllhandler();
#if PLATFORM_WINDOWS
	static std::string Exec(const char* cmd);
	static std::string GetLocalUserName();
#endif
	static void InitWinAndEditor();
	static void InitLinuxDS();
	static FString GetVersion(const FString& VersionPath);
	static void OnSystemError();
	// Lua Trace
	static void WriteLog(FString FilePath, FString Out);
	static void AddLuaTrace(const FString& FilePath, const FString& ErrorString);
};
HIGAME_API DECLARE_LOG_CATEGORY_EXTERN(LogUHiCrashSight, Log, All);
