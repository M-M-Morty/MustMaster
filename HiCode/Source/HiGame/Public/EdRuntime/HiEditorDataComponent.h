#pragma once

#include "CoreMinimal.h"
#include "HiEditorDataComponent.generated.h"


UCLASS(Blueprintable)
class UHiEditorDataComponent : public UActorComponent
{
	GENERATED_BODY()
	
public:
	UHiEditorDataComponent(const FObjectInitializer& ObjectInitializer = FObjectInitializer::Get());
	virtual void InitializeComponent() override;
	virtual void UninitializeComponent() override;
	virtual void BeginPlay() override;

	UFUNCTION(BlueprintImplementableEvent)
	void OnInitializeComponent();

	UFUNCTION(BlueprintImplementableEvent)
	void OnUninitializeComponent();
};