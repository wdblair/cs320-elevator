all:: elevator

elevator: elevator.dats
	atscc -o elevator $< -ljansson

.phony: clean

clean: 
	rm *.c *.o elevator