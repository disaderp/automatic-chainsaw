bool char_compare (char *x, char *y){
	while (*x != 0 || *y != 0){
		if (*x != *y){
			return false;
		}
		x++;
		y++;
	}
	return true;
}

bool char_compare_l (char *x, char *y, int l){
	if (l < 0) {
		return false;
	}
	int i = 0;
	while (i != l){
		if (*x != *y){
			return false;
		}
		x++;
		y++;
		i++;
	}
	return true;
}
