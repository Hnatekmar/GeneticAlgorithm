module simdutil;

import core.simd;

auto unpacked(T, uint size)(ref __vector(T[size]) x) {
	return (cast(T*) &x)[0..size];
}

auto unpacked(T, uint size)(__vector(T[size])[] x) {
	return (cast(T*) x.ptr)[0..x.length * size];
}
