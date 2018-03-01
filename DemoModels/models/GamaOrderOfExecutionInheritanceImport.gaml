/**
* Name: GamaOrderOfExecutionInheritanceImport
* Author: steffen
* Description: This model demonstrates order of execution when a model is split over multiple model files AKA
* importing models. In this the "inheritance import" is shown. This will merge everything in the models. Somehow this
* breaks monitors that access world? See below in the experiment description.
* Tags: Tag1, Tag2, TagN
*/
model GamaOrderOfExecutionInheritanceImport

// this is a "inheritance import" as described in http://gama-platform.org/tutorials#ModelOrganization#12_1_57_concept-import
import "GamaOrderOfExecution.gaml"

//FIXME two globals basically ruin it in subtle ways. Monitors for example seem to trip now (see below!) Are there more?
global
{
    init
    {
        write string(self) + ": INHERITANCEIMPORT.global.init()";
        write string(self) + ":" + "    creating SpeciesC";
        create SpeciesC number: 1;
        write string(self) + ":" + "END OF INHERITANCEIMPORT.global.init()";
    }

    string get_string (string msg)
    {
        write string(self) + ": " + msg;
        return "got string :-)";
    }

}

/**
 * SpeciesC - inherits from BaseSpecies.
 * Has an init(), a reflex and an aspect.
 */
species SpeciesC parent: BaseSpecies
{
    init
    {
        write string(self) + ":" + "SpeciesC.init()";
    }

    reflex reflexC
    {
        write string(self) + ": " + " SpeciesC.reflexC";
        write string(self) + ": calling world.get_int()...";
        int foo <- world.get_int("world.get_int() called from SpeciesC");
        write string(self) + ": calling world.get_string()...";
        string bar <- world.get_string("world.get_string() called from SpeciesC");
        write string(self) + ": " + " END OF SpeciesC.reflexC";
    }

    aspect aspectA
    {
        draw sphere(1) color: #green;
        write string(self) + ":" + "SpeciesC.aspectA";
    }

}

/**
 * Experiment: InheritanceImportOrderOfExecution
 * Displays the grid and SpeciesC. Monitors 1 and 2 are basically broken. Probably because fo the two globals?
 */
experiment InheritanceImportOrderOfExecution type: gui
{
    output
    {
    //This compiles but crashes when run. Probably because there are two globals.
    //Also the original experiment "OrderOfExecution" does not run anymore. Or at least the monitors prevent the displayf rom being shown.
    //This neither works when using "simulation" instead of "world". Both version compile, but none of them runs.
    //        monitor "monitor 1" value: world.get_int("INHERITANCEIMPORT.experiment.monitor1 <- 1") refresh: every(2 # cycles);
//        monitor "monitor 2" value: world.get_string("INHERITANCEIMPORT.experiment.monitor2 <- 'got string'") refresh: every(1#cycle);
        monitor "monitor 3" value: "Fixed value!" refresh: every(1 # cycle);
        display name: "InheritanceImportDisplay" refresh: every(1 # cycles) type: opengl
        {
            grid GridSpeciesA lines: # black;
            species SpeciesC aspect: aspectA;
            species SpeciesB;
        }

    }

}