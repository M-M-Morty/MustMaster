#pragma once
#include "CoreMinimal.h"
#include "UObject/Interface.h"
#include "InteractItemComponent.h"
#include "UInteractExecutorInterface.generated.h"

UINTERFACE(Blueprintable)
class HIGAME_API UInteractExecutorInterface : public UInterface
{
	GENERATED_BODY()
};

class HIGAME_API IInteractExecutorInterface
{
	GENERATED_BODY()

public:	
	UFUNCTION(BlueprintCallable, BlueprintNativeEvent)
	bool CanBeInteracted();

	UFUNCTION(BlueprintCallable, BlueprintNativeEvent)
	bool CanBeFocused();
	
	UFUNCTION(BlueprintCallable,BlueprintNativeEvent)
    bool TryInteract(FInteractQueryParam QueryParam, AActor* InteractItem, UInteractItemComponent* InteractItemComponent);

	UFUNCTION(BlueprintCallable,BlueprintNativeEvent)
	bool QuitInteract(AActor* InteractItem, UInteractItemComponent* InteractItemComponent);
};

DECLARE_DYNAMIC_MULTICAST_DELEGATE_ThreeParams(FOnInteractLevelExecuteMultiCast,FInteractQueryParam, QueryParam, AActor*, InteractItem,UInteractItemComponent*, InteractItemComponent);

UINTERFACE(Blueprintable)
class HIGAME_API UInteractLevelExecutorInterface : public UInterface
{
	GENERATED_BODY()
};

class HIGAME_API IInteractLevelExecutorInterface
{
	GENERATED_BODY()
	public:	
	UFUNCTION(BlueprintCallable,BlueprintImplementableEvent)
	bool TryInteract(FInteractQueryParam QueryParam, AActor* InteractItem, UInteractItemComponent* InteractItemComponent);
};
