// Fill out your copyright notice in the Description page of Project Settings.


#include "CrashSight/HiCrashSight.h"

#include <fstream>

#if WITH_PLUGINS_UNLUA
#include "LuaCore.h"
#include "LuaEnv.h"
#include "UnLuaDelegates.h"
#endif
#include "Kismet/KismetSystemLibrary.h"
#include "Engine/GameViewportClient.h"

#if PLATFORM_LINUX
#include "CrashSightAgent.h" 
#elif PLATFORM_WINDOWS
#include<Windows.h> 
#include <Lmcons.h>
#endif

DEFINE_LOG_CATEGORY(LogUHiCrashSight);

void UHiCrashSight::InitDllhandler()
{
#if PLATFORM_WINDOWS
	if (!dllHandler)
	{
		dllHandler = LoadLibraryA("CrashSight64.dll");
	}
	TCHAR bufCurrentDirectory[MAX_PATH + 1] = { 0 };
	DWORD dwNumCharacters = ::GetCurrentDirectory(MAX_PATH, bufCurrentDirectory);
	UE_LOG(LogUHiCrashSight, Log, TEXT("InitDllhandler: dllHandler=%s cur_dir=%s error=%d"), dllHandler ? *FString("success") : *FString("failed"), \
										*FString(bufCurrentDirectory),\
										dllHandler ? 0 : GetLastError());
#endif
}

#if PLATFORM_WINDOWS
std::string UHiCrashSight::Exec(const char* cmd) 
{
    std::array<char, 128> buffer;
    std::string result;
    std::unique_ptr<FILE, decltype(&_pclose)> pipe(_popen(cmd, "r"), _pclose);
    if (!pipe) 
	{
        throw std::runtime_error("popen() failed!");
    }
    while (fgets(buffer.data(), buffer.size(), pipe.get()) != nullptr) 
	{
        result += buffer.data();
    }
    return result;
}

std::string UHiCrashSight::GetLocalUserName()  
{  
	char currentUser[256]{};
	DWORD dwSize_currentUser = 256;
	::GetUserNameA(currentUser, &dwSize_currentUser);
	return std::string(currentUser);
}  
#endif

void UHiCrashSight::AddLuaTrace(const FString& FilePath, const FString& ErrorString)
{
	if (CrashLuaTraces.Num() < 100)
	{
		CrashLuaTraces.PushLast(ErrorString);
	}
	else
	{
		CrashLuaTraces.PopFirst();
		CrashLuaTraces.PushLast(ErrorString);
	}
	FString Out;
	for (int index = 0; index < CrashLuaTraces.Num(); index++)
	{
		FString ErrString = CrashLuaTraces[index];
		Out.Append(ErrString);
	}
	WriteLog(FilePath, Out);
}

void UHiCrashSight::WriteLog(FString FilePath, FString Out)
{
	FFileHelper::SaveStringToFile(Out, *FilePath);
}

FString UHiCrashSight::GetVersion(const FString& VersionPath)
{
	// 获取发布时保存的版本号，规则是: 引擎版本号_HiGame版本号; 读取当前目录的 Version 版本号文件 (488825f78@develop_433603c6d94@develop)
	FString Version = FString("1.0.0");
	std::ifstream Versionfile;
	Versionfile.open(*VersionPath, std::ifstream::binary); 
	if(Versionfile.is_open() && Versionfile.good())
	{
		std::string buffer;
		std::getline(Versionfile, buffer);
		Version = FString(buffer.c_str());
		Versionfile.close();
	}
	return Version;
}

void UHiCrashSight::InitWinAndEditor()
{
	// Windows 和 Editor 的 初始化
#if PLATFORM_WINDOWS 
	InitDllhandler();
	CS_UnrealCriticalErrorEnableHi(true);
	CS_AddValidExpCodeHi(0x000bdb30);
	MonitorEnableHi(false);
	FString UserID = FString("NULL");
	FString Version = FString("1.0.0");
	FString Key = FString("");
	// 编辑器 user_id 先获取 git username
	//std::string exe_ret = Exec("git config user.name");
	std::string exe_ret = GetLocalUserName();
	exe_ret.erase(std::remove(exe_ret.begin(), exe_ret.end(), '\n'), exe_ret.cend());
	UserID = FString(exe_ret.c_str());
	Key = FString("0948753a-704d-4dd1-9cec-0ed8ff7ae2a2");
	FString LPath = FPaths::ProjectDir() + FString("Saved/Logs/HiGame.log");
	FString VersionPath = FPaths::ProjectDir() + FString("Binaries/Version");
#if !WITH_EDITOR
	Key = FString("6e537920-1ec9-41f6-aa30-81ddbf7d0eb0");
	UE_LOG(LogUHiCrashSight,Log,TEXT("GameDir: LPath=%s VersionPath=%s"), *LPath, *VersionPath);	
	//LPath = FString("./HiGame/Saved/Logs/HiGame.log");
	//VersionPath = FString("./HiGame/Binaries/Version");
#endif
	SetCustomLogDirHi(LPath);
	Version = GetVersion(VersionPath);
	WinVersion = Version;
	FString TestPath = FPaths::ProjectDir() + FString("Binaries/Test");
	bTest = FPaths::FileExists(TestPath);
	// HiGame log print git log & timestamp
	FString LogVersion = Version;
	FString LogVersionPath = FPaths::ProjectDir() + FString("Binaries/VersionEX");
	std::ifstream LogVersionfile;
	LogVersionfile.open(*LogVersionPath, std::ifstream::binary); 
	if(LogVersionfile.is_open() && LogVersionfile.good())
	{
		std::string ret;
		char buffer[100];
		while (!LogVersionfile.eof())
		{

			LogVersionfile.getline(buffer, 100);
			ret = ret.append(buffer);
		}
		LogVersion = FString(ret.c_str());
		LogVersionfile.close();
	}

	SetTQMConfigHi(UserID, Version, LogVersion, Key);
	//ReportExceptionHi(FString("exp name"), FString("exp message"), FString("stack"), FString("extras"));
#endif
}

void UHiCrashSight::InitLinuxDS()
{
#if PLATFORM_LINUX
	GCloud::CrashSight::CrashSightAgent::ConfigDebugMode(true);
	// 设置上报域名，请根据项目发行需求进行填写。（必填）
	GCloud::CrashSight::CrashSightAgent::ConfigCrashServerUrl("pc.crashsight.qq.com");
	// 设置上报所指向的APP ID, 并进行初始化。APP ID可以在管理端更多->产品设置->产品信息中找到。（必填）
	FString LPath = FPaths::ProjectDir() + FString("Saved/Logs/HiGame.log");
	GCloud::CrashSight::CrashSightAgent::SetLogPath(TCHAR_TO_ANSI(*LPath));
	FString VersionPath = FPaths::ProjectDir() + FString("Binaries/Version");
	FString Version = GetVersion(VersionPath);

	GCloud::CrashSight::CrashSightAgent::Init("e46395c209", "96f67a71-f5ed-4872-bdf4-141232bd0c36", TCHAR_TO_ANSI(*Version));
	GCloud::CrashSight::CrashSightAgent::SetUserId("Linux_DS");
#endif
}

UHiCrashSight::UHiCrashSight()
{
#if PLATFORM_WINDOWS
	InitWinAndEditor();
#elif PLATFORM_LINUX
	InitLinuxDS();
#endif

#if WITH_PLUGINS_UNLUA
	FUnLuaDelegates::ReportLuaCallError.BindLambda([=](lua_State* L)
	{
		int32 Type = lua_type(L, -1);
        if (Type == LUA_TSTRING)
        {
            const char *ErrorString = lua_tostring(L, -1);
            luaL_traceback(L, L, ErrorString, 1);
            ErrorString = lua_tostring(L, -1);
			ReportExceptionHi(FString("LogUnLua"), FString("Lua error message:"), FString(ErrorString), FString(""));
            UE_LOG(LogUnLua, Error, TEXT("Lua error message: %s"), UTF8_TO_TCHAR(ErrorString));
        }
        else if (Type == LUA_TTABLE)
        {
            // multiple errors is possible
            int32 MessageIndex = 0;
            lua_pushnil(L);
            while (lua_next(L, -2) != 0)
            {
                const char *ErrorString = lua_tostring(L, -1);
				ReportExceptionHi(FString("LogUnLua"), FString("Lua error message:"), FString(ErrorString), FString(std::to_string(MessageIndex).c_str()));
                UE_LOG(LogUnLua, Error, TEXT("Lua error message %d : %s"), MessageIndex++, UTF8_TO_TCHAR(ErrorString));
                lua_pop(L, 1);
            }
        }
        lua_pop(L, 1);
		return Type;
	});
#endif

	OnHandleSystemErrorHandle = FCoreDelegates::OnHandleSystemError.AddStatic(&UHiCrashSight::OnSystemError);
	OnHandleSystemEnsureHandle = FCoreDelegates::OnHandleSystemEnsure.AddStatic(&UHiCrashSight::OnSystemError);
	ViewportCreatedHandle = UGameViewportClient::OnViewportCreated().AddLambda([] {
#if PLATFORM_WINDOWS 
		FString Title = FString("HiGame(") + WinVersion + FString(")");
		if (bTest)
		{
			Title = FString(L"HiGame测试服(") + WinVersion + FString(")");
		}
		UKismetSystemLibrary::SetWindowTitle(FText::FromString(Title));
#endif
	});
}

 void UHiCrashSight::OnSystemError()
{
	if (!IsInGameThread())
		return;

	FString ErrString;
#if WITH_PLUGINS_UNLUA
	for (auto& Pair : UnLua::FLuaEnv::GetAll())
	{
		if (!Pair.Key || !Pair.Value)
			continue;

		lua_State* L = Pair.Key;

		if (!L)
			continue;

        luaL_traceback(L, L, "", 0);
		ErrString.Append(FString::Printf(TEXT("LogUnLua: %s: %s\n"), *Pair.Value->GetName(), UTF8_TO_TCHAR(lua_tostring(L,-1))));
        //UE_LOG(LogUnLua, Log, TEXT("%s"), UTF8_TO_TCHAR(lua_tostring(L,-1)));
        lua_pop(L, 1);

		//UE_LOG(LogUnLua, Log, TEXT("%s:"), *Pair.Value->GetName())
		//PrintCallStack(Pair.Key);
		//UE_LOG(LogUnLua, Log, TEXT(""))
	}
#endif


	UE_LOG(LogUHiCrashSight,Log,TEXT("OnSystemError: ErrString=%s"), *ErrString);	

	static int32 CallCount = 0;
	int32 NewCallCount = FPlatformAtomics::InterlockedIncrement(&CallCount);
	if (NewCallCount != 1)
	{
		return;
	}
	
	GIsGuarded				= 0;
	GIsRunning				= 0;
	GIsCriticalError		= 1;
	GLogConsole				= NULL;
	GErrorHist[UE_ARRAY_COUNT(GErrorHist)-1]=0;

	for (const TCHAR* LineStart = GErrorHist;; )
	{
		TCHAR SingleLine[1024];

		// Find the end of the current line
		const TCHAR* LineEnd = LineStart;
		TCHAR* SingleLineWritePos = SingleLine;
		int32 SpaceRemaining = UE_ARRAY_COUNT(SingleLine) - 1;

		while (SpaceRemaining > 0 && *LineEnd != 0 && *LineEnd != '\r' && *LineEnd != '\n')
		{
			*SingleLineWritePos++ = *LineEnd++;
			--SpaceRemaining;
		}

		// cap it
		*SingleLineWritePos = 0;

		// prefix function lines with [Callstack] for parsing tools
		const TCHAR* Prefix = (FCString::Strnicmp(LineStart, TEXT("0x"), 2) == 0) ? TEXT("[Callstack] ") : TEXT("");

		// if this is an address line, prefix it with [Callstack]
		ErrString.Append(FString::Printf(TEXT("%s%s\n"), Prefix, SingleLine));
		
		// Quit if this was the last line
		if (*LineEnd == 0)
		{
			break;
		}

		// Move to the next line
		LineStart = (LineEnd[0] == '\r' && LineEnd[1] == '\n') ? (LineEnd + 2) : (LineEnd + 1);
	}

	ReportExceptionHi(FString("LogUnLua"), FString("Lua error message:"), FString(ErrString), FString(""));
}

 UHiCrashSight::~UHiCrashSight()
{
	 if (OnHandleSystemErrorHandle.IsValid())
	 {
		 FCoreDelegates::OnHandleSystemError.Remove(OnHandleSystemErrorHandle);
		 OnHandleSystemErrorHandle.Reset();
	 }
	if (OnHandleSystemEnsureHandle.IsValid())
	 {
		 FCoreDelegates::OnHandleSystemError.Remove(OnHandleSystemEnsureHandle);
		 OnHandleSystemEnsureHandle.Reset();
	 }
	if (ViewportCreatedHandle.IsValid())
	{
		UGameViewportClient::OnViewportCreated().Remove(ViewportCreatedHandle);
		ViewportCreatedHandle.Reset();
	}
}

/////////////////// BP Call Begin /////////////
void UHiCrashSight::SetTQMConfigHi(const FString& UserID, const FString& Version, const FString& LogVersion, const FString& Key)
{
#if PLATFORM_WINDOWS
	// https://crashsight.qq.com/docs/zh/crashsight/sdkDocuments/pc-sdk.html
	if (dllHandler)
	{
		UE_LOG(LogUHiCrashSight,Log,TEXT("SetTQMConfigHi: UserID=%s HiGameVersion=%s"), *UserID, *LogVersion);	
		SetTQMConfig theSetTQMConfig = NULL;
		theSetTQMConfig = (SetTQMConfig)GetProcAddress(dllHandler, "SetTQMConfig");
		if (theSetTQMConfig != NULL)
		{
			theSetTQMConfig(TCHAR_TO_ANSI(*UserID), TCHAR_TO_ANSI(*Version), TCHAR_TO_ANSI(*Key));
		}
	}
#endif
}

void UHiCrashSight::ReportExceptionHi(const FString& ExpName, const FString& ExpMessage, const FString& StackTrace, const FString& Extras)
{
#if PLATFORM_WINDOWS
	if (dllHandler)
	{
		reportException theReportException = NULL;
		theReportException = (reportException)GetProcAddress(dllHandler, "reportException");
		if (theReportException != NULL)
		{
			int type = 1;
			theReportException(type, TCHAR_TO_ANSI(*ExpName), TCHAR_TO_ANSI(*ExpMessage), TCHAR_TO_ANSI(*StackTrace), TCHAR_TO_ANSI(*Extras));
		}
	}
#elif PLATFORM_LINUX
	GCloud::CrashSight::CrashSightAgent::ReportException(1, TCHAR_TO_ANSI(*ExpName), TCHAR_TO_ANSI(*ExpMessage), TCHAR_TO_ANSI(*StackTrace), TCHAR_TO_ANSI(*Extras), 0, 0);
#endif
}

void UHiCrashSight::GenCrash()
{
	//int *a = NULL; 
	//a[0] = 1;
	ensureMsgf(false, TEXT("UHiCrashSight::GenCrash -> ensureMsgf"));
	//check(false);
}

void UHiCrashSight::SetUserValueHi(const FString& Key, const FString& Value)
{
#if PLATFORM_WINDOWS
// https://crashsight.qq.com/docs/zh/crashsight/webDocuments/custom-key-value.html#3.1
	if (dllHandler)
	{
		SetUserValue theCsSetUserValue = NULL;
		theCsSetUserValue = (SetUserValue)GetProcAddress(dllHandler, "SetUserValue");
		if (theCsSetUserValue != NULL)
		{
			theCsSetUserValue(TCHAR_TO_ANSI(*Key), TCHAR_TO_ANSI(*Value));
		}
	}
#endif
}

void UHiCrashSight::CsReportCrashHi()
{
#if PLATFORM_WINDOWS
	if (dllHandler)
	{
		CsReportCrash cs_report_crash = NULL;
		cs_report_crash = (CsReportCrash)GetProcAddress(dllHandler, "CsReportCrash");
		if (cs_report_crash != NULL)
		{
			FCoreDelegates::OnShutdownAfterError.AddStatic(cs_report_crash);
		}
	}
#endif
}

int UHiCrashSight::SetCustomLogDirHi(const FString& LPath)
{
#if PLATFORM_WINDOWS
	if (dllHandler)
	{
		SetCustomLogDir theSetCustomLogDir = NULL;
		theSetCustomLogDir = (SetCustomLogDir)GetProcAddress(dllHandler, "SetCustomLogDir");
		if (theSetCustomLogDir != NULL)
		{
			return theSetCustomLogDir(TCHAR_TO_ANSI(*LPath));
		}
	}
#endif
	return 0;
}
/////////////////// BP Call End /////////////

#if PLATFORM_WINDOWS
void UHiCrashSight::SetCrashCallbackHi(CrashCallbackFuncPtr callback)
{
	if (dllHandler)
	{
		SetCrashCallback theCallBack = NULL;
		theCallBack = (SetCrashCallback)GetProcAddress(dllHandler, "SetCrashCallback");
		if (theCallBack != NULL)
		{
			theCallBack(callback);
		}
	}
}

void UHiCrashSight::PrintLogHi(LogSeverity level, const char* tag, const char* format, ...)
{
	if (dllHandler)
	{
		PrintLog theCsPrintLog = NULL;
		theCsPrintLog = (PrintLog)GetProcAddress(dllHandler, "PrintLog");
		if (theCsPrintLog != NULL)
		{
			va_list args;
			va_start(args, format);
			theCsPrintLog(level, tag, format, args);
			va_end(args);
		}
	}
}
#endif

void UHiCrashSight::SetVehEnableHi(bool enable)
{
#if PLATFORM_WINDOWS
	if (dllHandler)
	{
		SetVehEnable theSetVehEnable = NULL;
		theSetVehEnable = (SetVehEnable)GetProcAddress(dllHandler, "SetVehEnable");
		if (theSetVehEnable != NULL)
		{
			theSetVehEnable(enable);
		}
	}
#endif
}

void UHiCrashSight::SetExtraHandlerHi(bool extra_handle_enable)
{
#if PLATFORM_WINDOWS
	/*
	* 设置额外的异常处理机制，默认为关闭，与旧版保持一致。 开启后，可以捕获上报strcpy_s一类的安全函数抛出的非法参数崩溃，以及，虚函数调用purecall错误导致的崩溃
	*/
	if (dllHandler)
	{
		SetExtraHandler theSetExtraHandler = NULL;
		theSetExtraHandler = (SetExtraHandler)GetProcAddress(dllHandler, "SetExtraHandler");
		if (theSetExtraHandler != NULL)
		{
			theSetExtraHandler(extra_handle_enable);
		}
	}
#endif

}

void UHiCrashSight::MonitorEnableHi(bool enable)
{
#if PLATFORM_WINDOWS
	if (dllHandler)
	{
		MonitorEnable monitor_enable = NULL;
		monitor_enable = (MonitorEnable)GetProcAddress(dllHandler, "MonitorEnable");
		if (monitor_enable != NULL)
		{
			UE_LOG(LogUHiCrashSight,Log,TEXT("MonitorEnableHi: enable=%d"), enable);	
			monitor_enable(enable);
		}
	}
#endif

}

void UHiCrashSight::CS_UnrealCriticalErrorEnableHi(bool enable)
{
#if PLATFORM_WINDOWS
	if (dllHandler)
	{
		CS_UnrealCriticalErrorEnable criticalerror_enable = NULL;
		criticalerror_enable = (CS_UnrealCriticalErrorEnable)GetProcAddress(dllHandler, "CS_UnrealCriticalErrorEnable");
		if (criticalerror_enable != NULL)
		{
			UE_LOG(LogUHiCrashSight,Log,TEXT("CS_UnrealCriticalErrorEnableHi : enable=%d"), enable);	
			criticalerror_enable(enable);
		}
	}
#endif
}


void UHiCrashSight::CS_AddValidExpCodeHi(unsigned long exp_code)
{
#if PLATFORM_WINDOWS
	if (dllHandler)
	{
		CS_AddValidExpCode addvalidexpcode = NULL;
		addvalidexpcode = (CS_AddValidExpCode)GetProcAddress(dllHandler, "CS_AddValidExpCode");
		if (addvalidexpcode != NULL)
		{
			UE_LOG(LogUHiCrashSight,Log,TEXT("CS_AddValidExpCodeHi: exp_code=%d"), exp_code);	
			addvalidexpcode(exp_code);
		}
	}
#endif
}
