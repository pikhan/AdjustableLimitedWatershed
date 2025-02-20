import ij.plugin.filter.PlugInFilter;
import ij.plugin.filter.MaximumFinder;
import ij.plugin.filter.EDM;
import ij.*;
import ij.process.*;
import ij.plugin.filter.ParticleAnalyzer;
import ij.measure.ResultsTable;
import ij.measure.Measurements;
import ij.plugin.ImageCalculator;

public class Enhanced_Adjustable_Watershed_Headless implements PlugInFilter {
    private double tolerance = 0.625;
    private double edmThreshold = 0;
    private double smoothingSigma = 0;
    private double maxLineLength = 50;
    private boolean restrictToBlack = false;

    public int setup(String arg, ImagePlus imp) {
        return DOES_8G;
    }

    public void run(ImageProcessor ip) {
        // Get parameters from macro options
        String options = Macro.getOptions();
        if (options != null && !options.isEmpty()) {
            try {
                tolerance = Double.parseDouble(Macro.getValue(options, "tolerance", String.valueOf(tolerance)));
                edmThreshold = Double.parseDouble(Macro.getValue(options, "edmThreshold", String.valueOf(edmThreshold)));
                smoothingSigma = Double.parseDouble(Macro.getValue(options, "smoothingSigma", String.valueOf(smoothingSigma)));
                maxLineLength = Double.parseDouble(Macro.getValue(options, "maxLineLength", String.valueOf(maxLineLength)));
                restrictToBlack = Boolean.parseBoolean(Macro.getValue(options, "restrictToBlack", String.valueOf(restrictToBlack)));
            } catch (NumberFormatException e) {
                IJ.log("Debug: Invalid number format in options: " + e.getMessage());
                return;
            } catch (IllegalArgumentException e) {
                IJ.log("Debug: Invalid argument in options: " + e.getMessage());
                return;
            }
        } else {
            IJ.log("Debug: No options provided, using defaults");
        }

        // Get current image and check if it's valid
        ImagePlus imp = WindowManager.getCurrentImage();
        if (imp == null || !imp.getProcessor().isBinary()) {
            IJ.error("Binary Image required");
            return;
        }

        // Generate EDM with proper background handling
        boolean invertedLut = imp.isInvertedLut();
        boolean background255 = (invertedLut && Prefs.blackBackground) ||
                (!invertedLut && !Prefs.blackBackground);

        int backgroundValue = background255 ? (byte)255 : 0;
        FloatProcessor floatEdm = new EDM().makeFloatEDM(ip, backgroundValue, false);

        // Apply EDM threshold if specified
        if (edmThreshold > 0) {
            floatEdm.setThreshold(edmThreshold, Double.MAX_VALUE, ImageProcessor.NO_LUT_UPDATE);
            ByteProcessor thresholdedEdm = floatEdm.createMask();
            floatEdm = (FloatProcessor)thresholdedEdm.convertToFloat();
        }

        // Apply Gaussian smoothing if specified
        if (smoothingSigma > 0) {
            floatEdm.blurGaussian(smoothingSigma);
        }

        // Detect Maxima
        MaximumFinder maxFinder = new MaximumFinder();
        ByteProcessor segmented = maxFinder.findMaxima(floatEdm, tolerance,
                ImageProcessor.NO_THRESHOLD, MaximumFinder.SEGMENTED, false, true);

        if (maxLineLength > 0) {
            // Isolate and filter watershed lines
            ByteProcessor watershedLines = (ByteProcessor)segmented.duplicate();
            ImageCalculator ic = new ImageCalculator();
            ImagePlus imp1 = new ImagePlus("", ip);
            ImagePlus imp2 = new ImagePlus("", watershedLines);
            ImagePlus result = ic.run("Subtract create", imp1, imp2);
            watershedLines = (ByteProcessor)result.getProcessor();

            // Filter lines using particle analyzer
            ParticleAnalyzer pa = new ParticleAnalyzer(
                    ParticleAnalyzer.SHOW_MASKS,
                    Measurements.AREA,
                    new ResultsTable(),
                    0, maxLineLength);
            pa.analyze(new ImagePlus("", watershedLines));

            // Get result and invert
            segmented = (ByteProcessor)WindowManager.getCurrentImage().getProcessor();
            segmented.invert();
        }

        // Handle restriction to black regions
        if (restrictToBlack) {
            ByteProcessor edmMask = floatEdm.createMask();
            ImageCalculator ic = new ImageCalculator();
            ImagePlus imp1 = new ImagePlus("", segmented);
            ImagePlus imp2 = new ImagePlus("", edmMask);
            ImagePlus result = ic.run("AND create", imp1, imp2);
            segmented = (ByteProcessor)result.getProcessor();
        }

        // Apply segmentation back to original
        byte[] pixels = (byte[])ip.getPixels();
        byte[] segmPixels = (byte[])segmented.getPixels();
        for (int i = 0; i < pixels.length; i++) {
            if (segmPixels[i] == 0) {
                pixels[i] = (byte)0;
            }
        }
    }
}