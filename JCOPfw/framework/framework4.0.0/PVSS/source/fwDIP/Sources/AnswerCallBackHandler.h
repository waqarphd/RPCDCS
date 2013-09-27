#ifndef ANSWERCALLBACKHANDLER_H
#define ANSWERCALLBACKHANDLER_H

#include "WaitForAnswer.hxx"
#include "DpIdValueList.hxx"


/**
* Note that this handler is valid for one dpGet invocation (the should not 
* destroy the handler so us dpGet with the del parameter set to false). After this
* invocation the handler must be destroyed - DpIdValueList has no clear option.
*/
class CdpGetCallBackHandler:public WaitForAnswer{
	private:
		/// used to store the responses received by the handler.
		DpIdValueList responseList;

		/// counts number of answers received 
		int numAnswers;

	public:
		CdpGetCallBackHandler():numAnswers(0){}

		virtual ~ CdpGetCallBackHandler(){}

		void callBack(DpMsgAnswer &answer);

		/**
		* Gets the list of responses. This list is contains values which are
		* OWNED BY THE LIST - they MUST NOT be destroyed by the caller (unless cut from the list).
		*/
		const DpIdValueList & getListOfResponses() const{
			return responseList;
		}

		const int getNumOfResponses() const{
			return numAnswers;
		}
};



#endif

