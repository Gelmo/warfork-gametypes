gfx/arc/arc_point
{
	nopicmip
	deformVertexes autosprite

	{
		clampmap gfx/arc/arc_point_1.tga
		alphagen wave distanceramp 0.5 1 0 1600
		blendFunc blend
		rgbgen entity
	}

	{
		clampmap gfx/arc/arc_point_2.tga
		alphagen wave distanceramp 0.5 1 0 2000
		blendFunc blend
		tcMod rotate 6
	}

	{
		clampmap gfx/arc/arc_point_3.tga
		alphagen wave distanceramp 0 1 600 2000
		blendFunc blend
		rgbgen vertex
		tcMod rotate -3
	}
}
