#include <stdio.h>
#include <inttypes.h>
#include <string.h>
#include <assert.h>

extern void process_N_pixels(uint8_t *rgb, int bytes);

int main(void)
{
	static unsigned char in[1000000], out[1000000];

	FILE *f = fopen("baboon.raw", "rb");
	int bytes = fread(in, 1, 1000000, f);
	fclose(f);

	/* benchmark: run it 100.000 times */
#	ifdef BENCH
	for (int i=0; i<100000; i++)
		process_N_pixels(in, bytes - (bytes % 96));
	/* no benchmark: perform a self-test by doing the grayscale in Cs */
#	else
	memcpy(out, in, bytes);
	process_N_pixels(out, bytes - (bytes % 96));

	for (int i=0; i<bytes; i+=3) {
		int correct = (in[i] + in[i+1] + in[i+2]) / 3;

		if (out[i] != correct) {

			printf("Error at %d: (%u,%u,%u) -> (%u,%u,%u) != %u\n", i,
			in[i], in[i+1], in[i+2],
			out[i], out[i+1], out[i+2],
			correct);
		}
	}

	f = fopen("baboon-gray.raw", "wb");
	fwrite(out, 1, bytes, f);
	fclose(f);

#	endif
}
