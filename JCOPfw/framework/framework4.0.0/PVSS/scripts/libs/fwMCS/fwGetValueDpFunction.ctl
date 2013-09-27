int changeValue(anytype p1, string g1)
{
	anytype oldValue;
	int interval = 5;

	dpGet(g1, oldValue);
	dpSetWait(g1, p1);

	if ((oldValue-interval) > p1)
		return 1;
	else if ((oldValue+interval) < p1)
		return 2;
	else return 0;
}
