bool char_compare (char *x, char *y){
	bool b_areCharsEqual = true;
	while (*x != 0 || *y != 0){
		if (*x != *y) b_areCharsEqual = false;
		x++;
		y++;
	}
	return b_areCharsEqual;
}

bool char_compare_l (char *x, char *y, int l){
	if (l < 0) return false;
	bool b_areCharsEqual = true;
	int i = 0;
	while (i != l){
		if (*x != *y) b_areCharsEqual = false;
		x++;
		y++;
		i++;
	}
	return b_areCharsEqual;
}