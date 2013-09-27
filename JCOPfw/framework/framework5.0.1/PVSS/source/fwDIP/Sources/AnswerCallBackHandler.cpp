#include "PVSSDIPAPIOptions.h"
#include "AnswerCallBackHandler.h"
#include "AnswerGroup.hxx"
#include "DpMsgAnswer.hxx"
#include <iostream>
#include "dipManager.h"



void CdpGetCallBackHandler::callBack(DpMsgAnswer &answer){
	AnswerGroup * group =  answer.getFirstGroup();
	while (group != NULL){
		AnswerItem*  answerItem = group->getFirstItem();  
		while (answerItem){
			VariablePtr var = answerItem->getValuePtr(); 
			if (!var){
				PVSSERROR("var is null");
			}else{
				// store the value for later retreival
				responseList.appendItem(answerItem->getDpIdentifier(), *var);
				numAnswers++; // make sure inc is AFTER value added to list!
				//cout << "CdpGetCallBackHandler::callBack - got value " << var << endl;
			}
			answerItem = group->getNextItem();
		}
		group = answer.getNextGroup(); 
	}
}

