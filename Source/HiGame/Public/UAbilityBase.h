// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

/**
 * 
 */


class IAttributeCallback
{	
public:	
	virtual void HandleHealthChanged(float NewValue) = 0;	
};
