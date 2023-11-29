module hex_decoder(c,display);
	input [3:0] c;
	output [6:0] display;
	
	assign c0 = c[0];
	assign c1 = c[1];
	assign c2 = c[2];
	assign c3 = c[3];
	
	
	assign display[0] = ~((c3|c2|c1|~c0) & (c3|~c2|c1|c0) & (~c3|c2|~c1|~c0) & (~c3|~c2|c1|~c0));
	assign display[1] = ~((c3|~c2|c1|~c0) & (c3|~c2|~c1|c0) & (~c3|c2|~c1|~c0) & (~c3|~c2|c1|c0) & (~c3|~c2|~c1|c0) & (~c3|~c2|~c1|~c0));
	assign display[2] = ~((c3|c2|~c1|c0) & (~c3|~c2|c1|c0) & (~c3|~c2|~c1|c0) & (~c3|~c2|~c1|~c0));
	assign display[3] = ~((c3|c2|c1|~c0) & (c3|~c2|c1|c0) & (c3|~c2|~c1|~c0) & (~c3|c2|~c1|c0) & (~c3|~c2|~c1|~c0));
	assign display[4] = ~((c3|c2|c1|~c0) & (c3|c2|~c1|~c0) & (c3|~c2|c1|c0) & (c3|~c2|c1|~c0) & (c3|~c2|~c1|~c0) & (~c3|c2|c1|~c0));
	assign display[5] = ~((c3|c2|c1|~c0) & (c3|c2|~c1|c0) & (c3|c2|~c1|~c0) & (c3|~c2|~c1|~c0) & (~c3|~c2|c1|~c0));
	assign display[6] = ~((c3|c2|c1|c0) & (c3|c2|c1|~c0) & (c3|~c2|~c1|~c0) & (~c3|~c2|c1|c0));
	
	
endmodule