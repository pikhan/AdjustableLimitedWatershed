// Adjustable Watershed Macro with EDM modifications

// Create a dialog for user inputs
Dialog.create("Adjustable Watershed Options");
Dialog.addMessage("Adjustable Watershed with EDM modifications");
Dialog.addNumber("Tolerance (e.g., 0.625):", 0.625); // Default tolerance
Dialog.addNumber("EDM Threshold (0 to disable):", 0); // Threshold to mask EDM
Dialog.addNumber("Gaussian Smoothing Sigma (0 to disable):", 0); // Smoothing intensity
Dialog.addNumber("Max Watershed Line Length (e.g., 50 pixels):", 50); // Max length for watershed-added lines
Dialog.addCheckbox("Restrict flooding to black regions:", false);
Dialog.show();

// Retrieve user inputs
tolerance = Dialog.getNumber(); // Watershed sensitivity
edmThreshold = Dialog.getNumber(); // Threshold to exclude white areas
smoothingSigma = Dialog.getNumber(); // Smoothing for EDM
maxLineLength = Dialog.getNumber(); // Max length for watershed lines
restrictToBlack = Dialog.getCheckbox(); // Restrict flooding to black pixels

// Ensure an image is open and duplicate the original image
originalTitle = getTitle(); // Save the name of the original image
run("Duplicate...", "title=Original_Copy"); // Explicitly duplicate the image and name it "Original_Copy"

// Ensure the image is binary
selectImage(originalTitle); // Work on the original image
if (isBinary()) {
    print("Image is binary. Proceeding with segmentation...");
} else {
    print("Converting to binary...");
    setAutoThreshold("Minimum"); // Apply an automatic threshold
    run("Convert to Mask"); // Convert to binary (black and white)
    //print("Image converted to binary.");
}

// Generate EDM
run("Invert");
//run("Distance Map", "map=[32 bits]"); // Generate EDM as a 32-bit image
//rename("EDM");
eval("script",
    "// Get the current image as an ImageProcessor\n" +
    "var imp = Packages.ij.WindowManager.getCurrentImage();\n" +
    "var ip = imp.getProcessor();\n" +
    "\n" +
    "// Create EDM and generate the FloatProcessor\n" +
    "var edm = new Packages.ij.plugin.filter.EDM();\n" +
    "var floatEdm = edm.makeFloatEDM(ip, 0, false);\n" + // Assuming background is 255\n" +
    "\n" +
    "// Create and display the EDM as an ImagePlus\n" +
    "var edmImp = new Packages.ij.ImagePlus('EDM', floatEdm);\n" +
    "edmImp.setTitle('EDM');\n" +
    "edmImp.show();\n"
);

if (edmThreshold > 0) {
	//selectImage("EDM");
    setThreshold(edmThreshold, 9999999);
    run("Convert to Mask"); // Mask out areas below threshold
    run("Apply LUT");
}

// Apply Gaussian Smoothing if required
if (smoothingSigma > 0) {
    run("Gaussian Blur...", "sigma=" + smoothingSigma);
}

// Detect Maxima with the specified tolerance
//run("Find Maxima...", "prominence=" + tolerance + " output=[Segmented Particles] exclude edges=false useEDM=true");
//rename("Segmented_Particles"); // Rename the result for clarity
//
eval("script",
    "// Get the current EDM image as a FloatProcessor\n" +
    "var edmImage = Packages.ij.WindowManager.getImage('EDM');\n" +
    "var floatEdm = edmImage.getProcessor().convertToFloatProcessor();\n" +
    "\n" +
    "// Create MaximumFinder and run findMaxima()\n" +
    "var maxFinder = new Packages.ij.plugin.filter.MaximumFinder();\n" +
    "var segmentedImage = maxFinder.findMaxima(\n" +
    "    floatEdm, 0.625,\n" +
    "    Packages.ij.process.ImageProcessor.NO_THRESHOLD,\n" +
    "    Packages.ij.plugin.filter.MaximumFinder.SEGMENTED,\n" +
    "    false, true);\n" +
    "\n" +
    "// Create and display the segmented result\n" +
    "var segmentedImp = new Packages.ij.ImagePlus('Segmented_Particles', segmentedImage);\n" +
    "segmentedImp.setTitle('Segmented_Particles');\n" +
    "segmentedImp.show();\n"
);
if (maxLineLength > 0){
	// Step 7: Isolate Watershed Lines
	selectImage("Segmented_Particles");
	run("Duplicate...", "title=Watershed_Lines");
	selectImage("Watershed_Lines");
	imageCalculator("Subtract create", originalTitle, "Watershed_Lines"); // Subtract original from segmented
	run("Invert");
	rename("Isolated_Watershed_Lines");

	// Step 8: Filter Long Watershed Lines
	selectImage("Isolated_Watershed_Lines");
    setAutoThreshold("Minimum"); // Apply an automatic threshold
    run("Convert to Mask"); // Convert to binary (black and white)
	run("Analyze Particles...", "size=0-" + maxLineLength + " pixel show=Masks"); // Filter long watershed lines
	run("Invert");
	rename("Filtered_Watershed_Lines");
}


// Restrict flooding to black regions
if (restrictToBlack) {
    selectImage("EDM");
    setAutoThreshold("Default"); // Apply an automatic threshold
    run("Convert to Mask"); // Convert the thresholded EDM to a binary mask
    rename("EDM_Mask");
    imageCalculator("AND create", "Segmented_Particles", "EDM_Mask");
    rename("Restricted_Segmented_Particles");
}

// Overlay Segmentation Lines as Black Pixels
if (restrictToBlack) {
    selectImage("Restricted_Segmented_Particles");
} else {
    selectImage("Segmented_Particles");
}
// Use the "AND create" operation to overlay black pixels only
selectImage("Original_Copy");
if (restrictToBlack) {
	imageCalculator("AND create", "Original_Copy", "Restricted_Segmented_Particles"); // Ensure black pixels are added
} else {
	if (maxLineLength > 0){
		imageCalculator("AND create", "Original_Copy", "Filtered_Watershed_Lines");

	} else {
			imageCalculator("AND create", "Original_Copy", "Segmented_Particles"); // Ensure black pixels are added
	}

}
rename("Overlay_Result"); // Rename the overlay result

// Convert to Binary and Display Final Result
//run("Convert to Mask");
//rename("Segmented_Result");

// Utility function to check if the current image is binary
function isBinary() {
    getStatistics(nPixels, mean, stdDev, min, max);
    return (max == 255 && min == 0 && stdDev > 0);
}
