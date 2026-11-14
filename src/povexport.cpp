#include "povexport.h"

#include <QCoreApplication>
#include <QDateTime>
#include <QDebug>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QTextStream>

#include <QGLViewer/camera.h>

#include <cmath>

#include "appenv.h"
#include "objects/cam.h"
#include "objects/object.h"
#include "objects/terrain.h"
#ifdef HAS_LIB_ASSIMP
#include "objects/mesh.h"
#endif

using qglviewer::Vec;

namespace {


// Writes one of the interactive view's lights out as a POV-Ray vector.
//
// glLightfv(GL_POSITION) takes a homogeneous coordinate, so the point OpenGL
// really lights from is xyz/w -- the default GL_LIGHT0, btVector4(500, 500,
// 500, 0.4), lights from <1250,1250,1250> and not from <500,500,500>. A w of
// 0 asks for a light infinitely far off in the direction xyz; POV-Ray has no
// such light, so it gets one a long way along it instead, which is the same
// thing to within a rounding error at any scene's size.
//
// Z is negated last because POV-Ray is left-handed where the OpenGL and
// Bullet world is right-handed, the same conversion
// Object::povMatrixFromGL() applies to every object's transform.
void povLightDeclare(QTextStream &s, const char *name,
                            const btVector4 &light) {
  btVector3 p(light.x(), light.y(), light.z());

  if (light.w() != btScalar(0)) {
    p /= light.w();
  } else if (p.length2() > btScalar(0)) {
    p = p.normalized() * btScalar(1e5);
  }

  s << "#declare " << name << " = <" << p.x() << ", " << p.y() << ", "
    << -p.z() << ">;" << "\n";
}

// What follows SCENE in every exported scene's GNUmakefile: the targets that
// render, encode and submit the exported frames.
const char *const EXPORT_MK = R"MK(SHELL:=/bin/bash

# Cloud rendering host alias "ec2" according to your ~/.ssh/config
# see https://github.com/bullet-physics-playground/bpp/issues/8

EC2?=ec2

# Custom POV-Ray options

POV?=+W1280 +H720 -J +FN10

# Custom POV-Ray include directives

POVINC?=+LLightsysIV

# Custom ffmpeg loop times (default x10 loops)

MKV_LOOP?=10

# Extra options for scripts/povomatic-job.py (e.g. --res 1080p --priority 5)

POVOMATIC_ARGS?=

# ----------------------------------------------------------------------------

POVOPT=${POVINC} ${POV}

all: quick

help:
	@echo "usage:"
	@echo ""
	@echo " Local Rendering"
	@echo ""
	@echo "  make quick    # render quick"
	@echo "  make final    # render final"
	@echo ""
	@echo "  make mkv      # make ${SCENE}.mkv      with ffmpeg"
	@echo "  make mkv-loop # make ${SCENE}-loop.mkv (looped ${MKV_LOOP}) times with ffmpeg"
	@echo ""
	@echo "  make clean    # cleanup"
	@echo "  make dist     # cleanup and create ../${SCENE}.tar.xz"
	@echo ""
	@echo " Cloud Rendering on ${EC2}"
	@echo ""
	@echo "  make ec2-up    # make ${SCENE}.tar.xz, upload and extract it to ${EC2}:."
	@echo "  make ec2-down  # make ${SCENE}.mkv on ${EC2} with ffmpeg and scp to local machine"
	@echo ""
	@echo "  see https://github.com/bullet-physics-playground/bpp/issues/8 for POV-Ray on Amazon EC2"
	@echo " Cluster rendering using slurm"
	@echo ""
	@echo "  make slurm           # render using the slurm workload manager"
	@echo "  make kubernetes      # render using kubernets cluster"
	@echo "  make povomatic       # submit to povomatic (POVOMATIC_ARGS='--res 1080p ...')"
	@echo ""
	@echo " YouTube"
	@echo ""
	@echo "  make youtube-up      # make and upload ${SCENE}.mkv      to YouTube"
	@echo "  make youtube-up-loop # make and upload ${SCENE}-loop.mkv to YouTube"
	@echo ""

quick:
	povray ${SCENE}.ini -V +W380 +H252 +Q3 -A +D -C -CC ${POVOPT} || true

final: 720p

720p:
	povray ${SCENE}.ini -V +W1280 +H720 +Q11 +A0.3 ${POVOPT} || true

mkv:
	ffmpeg -y -err_detect ignore_err -pattern_type glob -i '*.png' $(if $(wildcard ${SCENE}.wav),-i '${SCENE}.wav' -c:a flac) -c:v libx264 -preset veryslow -qp 0 -r 25 -pix_fmt yuv444p '${SCENE}.mkv'

mkv-8k:
	ffmpeg -y -threads 1 -filter_threads 1 -filter_complex_threads 1 -err_detect ignore_err -i %05d.png -c:v libx265 -r 25 -crf 18 -preset slow -pix_fmt yuv420p10le -vf "colorspace=bt709:iall=bt709:range=tv:fast=1" -color_primaries bt709 -color_trc bt709 -colorspace bt709 -movflags +faststart '${SCENE}.mkv'

mov-8k:
	ffmpeg -y -threads 1 -filter_threads 1 -filter_complex_threads 1 -err_detect ignore_err -i %05d.png -c:v prores_ks -profile:v 3 -vendor apl0 -pix_fmt yuv422p10le -vf scale=7680:4320 '${SCENE}.mov'

mkv-loop: mkv
	for i in {1..${MKV_LOOP}}; do printf "file '%s'\n" ${SCENE}.mkv >> loop.txt; done
	ffmpeg -y -f concat -i loop.txt -c copy ${SCENE}-loop.mkv
	rm loop.txt

ec2-up:
	rsync -avz -e "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" --progress ../${SCENE}.tar.xz ${EC2}:.
	ssh ${EC2} "tar xvf ${SCENE}.tar.xz"

ec2-down:
	ssh ${EC2} "make -C ${SCENE} mkv"
	scp ${EC2}:${SCENE}/${SCENE}.mkv .

slurm:
	sbatch -J ${SCENE} -a 1-`ls -1 ?????.inc|wc -l` --export=POVOPT='${POVOPT}' ../povray.sbatch ${SCENE} `ls -1 *.inc | wc -l`

kubernetes:
	python3 ../../scripts/povray-job.py --start 1 --end `ls -1 ?????.inc | wc -l` --width 1280 --height 720 ${SCENE}.pov

log-povomatic-worker:
	kubectl -n povomatic logs deploy/worker -c worker -f

povomatic:
	python3 ../../scripts/povomatic-job.py ${POVOMATIC_ARGS} .

distclean: clean
	rm -f ${SCENE}.pov ${SCENE}.ini ?????.inc mesh_*.inc

clean:
	rm -f *.png *.mov *.mp4 *.mkv *.pov-state *.err *.out *.log ${SCENE}.wav

dist: clean
	cd .. && find ${SCENE} -print0 | sort -z | tar -cvJf ${SCENE}.tar.xz --no-recursion --null -T -
)MK";

} // namespace

namespace PovExport {

QString byline() {
  QString name = qgetenv("USER");
  if (name.isEmpty())
    name = qgetenv("USERNAME");

  QString timestamp =
      QDateTime::currentDateTime().toString("yyyy-MM-dd hh:mm:ss");
  return QString("%1 by %2").arg(timestamp, name);
}

void copySettingsIncludes(const QString &settingsInc, const QString &startupDir,
                          const QString &sceneDir) {
  // Keep sceneDir self-contained: copy the include the main scene pulls in
  // (includes/settings.inc, or the file a script names with v.pov_settings)
  // alongside the exported scene, rather than relying on the +L library
  // path to find the original when the scene is rendered later, elsewhere.
  // A name with no file under includes/ leaves sceneDir's copy alone. Outside
  // a source checkout (the Docker image runs from /work) includes/ is the
  // installed /usr/share/bpp/includes.
  // Search the places bpp's shipped includes can live: next to the
  // executable (build tree and macOS .app bundle), above it, the launch
  // directory, and the usual system install locations.  macOS apps keep
  // them at Contents/includes, one level above the executable.
  QStringList incDirs;
  QString appDir = QCoreApplication::applicationDirPath();
  incDirs << appDir + "/includes"
          << appDir + "/../includes"
          << appDir + "/../../includes"
          << startupDir + "/includes"
          << "/Applications/bpp.app/Contents/includes"
          << "/usr/local/share/bpp/includes"
          << "/opt/homebrew/share/bpp/includes"
          << "/usr/share/bpp/includes";

  QString settingsIncPath;
  for (const QString &dir : incDirs) {
    if (QFile::exists(dir + QDir::separator() + settingsInc)) {
      settingsIncPath = dir + QDir::separator() + settingsInc;
      break;
    }
  }

  if (!settingsInc.isEmpty() && !settingsIncPath.isEmpty() &&
      QFile::exists(settingsIncPath)) {
    // Keep the scene self-contained: copy the selected settings include plus
    // any sibling includes it pulls in (bpp_CIE.inc, bpp_CIE_tools.inc, ...)
    // so VFE/non-VFE renders that lack POV-Ray's configured include search
    // path can resolve them next to the scene.
    QString srcIncDir = QFileInfo(settingsIncPath).absolutePath();
    QDir srcQDir(srcIncDir);
    for (const QString &entry : srcQDir.entryList(QDir::Files)) {
      if (!entry.endsWith(".inc", Qt::CaseInsensitive))
        continue;
      QString dst = sceneDir + QDir::separator() + entry;
      QFile::remove(dst);
      QFile::copy(srcIncDir + QDir::separator() + entry, dst);
    }
  }
}

void writeIni(const QString &path, const QString &byline,
              const QString &sceneName, int firstFrame, int lastFrame) {
  QFile fileINI(path);
  fileINI.open(QFile::WriteOnly | QFile::Truncate);

  QTextStream ini(&fileINI);
  ini << "; Animation INI file generated by Bullet Physics Playground" << "\n";
  ini << "; " + byline << "\n"
      << "\n";
  ini << "Input_File_Name=" << sceneName << ".pov" << "\n";
  ini << "Output_File_Name=" << sceneName << "\n";
  ini << "Output_to_File=On" << "\n";
  ini << "Pause_When_Done=Off" << "\n";
  ini << "Verbose=Off" << "\n";
  ini << "Display=On" << "\n";
  ini << "Width=1280" << "\n";
  ini << "Height=720" << "\n";
  ini << "+FN" << "\n";
  ini << "+UA" << "\n";
  ini << "Bits_Per_Color=16" << "\n";
  ini << "+a +j0" << "\n";

  ini << "+L" << userCacheDir() << "\n";
  ini << "+L../../includes" << "\n" << "\n";
  ini << "+L/nfs/cache" << "\n" << "\n"; // XXX make this an option in the prefs

  ini << "Initial_Clock=" << firstFrame << "\n";
  ini << "Final_Clock="   << lastFrame << "\n";
  ini << "Final_Frame="   << lastFrame << "\n";

  ini << "[240p]" << "\n"
      << "Width=426" << "\n"
      << "Height=240" << "\n";
  ini << "[720p]" << "\n"
      << "Width=1280" << "\n"
      << "Height=720" << "\n";
  ini << "[1080p]" << "\n"
      << "Width=1920" << "\n"
      << "Height=1080" << "\n";
  ini << "[TikTok]" << "\n"
      << "Width=1080" << "\n"
      << "Height=1920" << "\n";
  ini << "[4K]" << "\n"
      << "Width=3840" << "\n"
      << "Height=2160" << "\n";
  ini << "[Apple-M1]" << "\n"
      << "Width=4480" << "\n"
      << "Height=2520" << "\n";
  ini << "[Apple-5K]" << "\n"
      << "Width=5120" << "\n"
      << "Height=2880" << "\n";
  ini << "[8K]" << "\n"
      << "Width=7680" << "\n"
      << "Height=4320" << "\n";
  ini << "[DIN-A4-landscape-300dpi-5mm-margin]" << "\n"
      << "Width=3470" << "\n"
      << "Height=2442" << "\n";
  ini << "[DIN-A4-landscape-600dpi-5mm-margin]" << "\n"
      << "Width=6780" << "\n"
      << "Height=4725" << "\n";
  ini << "[portrait]" << "\n"
      << "Width=600" << "\n"
      << "Height=800" << "\n";
}

void writeMain(const QString &path, const QString &byline, const Scene &scene) {
  QFile fileMain(path);
  fileMain.open(QFile::WriteOnly | QFile::Truncate);

  QTextStream smain(&fileMain);
  smain << "// Main POV file generated by Bullet Physics Playground" << "\n";
  smain << "// " + byline << "\n"
        << "\n";

  smain << "#version 3.8;" << "\n"
        << "\n";

  smain << "global_settings {\n";
  smain << "  assumed_gamma 1.0\n";
  smain << "  max_trace_level 15\n";
  smain << "}\n\n";

  if (scene.radiosity) {
    smain << "global_settings {\n";
    smain << "  radiosity {\n";
    smain << "    pretrace_start 0.08\n";
    smain << "    pretrace_end 0.01\n";
    smain << "    count 350\n";
    smain << "    nearest_count 10\n";
    smain << "    error_bound 0.5\n";
    smain << "    low_error_factor 0.2\n";
    smain << "    recursion_limit 2\n";
    smain << "  }\n";
    smain << "}\n\n";
  }

  if (scene.photons) {
    smain << "global_settings {\n";
    smain << "  photons {\n";
    smain << "    spacing 0.5\n";
    smain << "    gather 20 10\n";
    smain << "  }\n";
    smain << "}\n\n";
  }

  if (scene.fog) {
    smain << "// Fog\n";
    smain << "fog {\n";
    smain << "  fog_type 1\n";
    smain << "  distance 100\n";
    smain << "  color rgb <0.5, 0.5, 0.5>\n";
    smain << "}\n\n";
  }

  if (scene.atmosphere) {
    smain << "// Atmosphere\n";
    smain << "media { atmosphere }\n\n";
  }

  // The interactive view's two lights, for the settings include to pick up,
  // so that a script moving them with v.glLight0 or v.glLight1 is rendered
  // the way its view looks. The include declares its own defaults where this
  // preamble is missing, which is what makes a hand-written scene that does
  // not have it still render.
  //
  // They go in the main scene rather than in the per-frame include because
  // the settings file, which reads them, is included ahead of that; a scene
  // whose lights move while it runs therefore renders every one of its frames
  // with the lights as they stood when the export last wrote this file.
  povLightDeclare(smain, "GL_Light0", scene.light0);
  povLightDeclare(smain, "GL_Light1", scene.light1);
  smain << "#declare GL_Diffuse = <" << scene.diffuse.x() << ", "
        << scene.diffuse.y() << ", " << scene.diffuse.z() << ">;" << "\n"
        << "\n";

  if (!scene.settingsInc.isEmpty()) {
    smain << "#include \"" + scene.settingsInc + "\"" << "\n"
          << "\n";
  }

  smain << "#include concat(concat(str(clock,-5,0)),\".inc\")" << "\n"
        << "\n";
}

void writeFrame(const QString &path, const QString &byline,
                const QString &preSDL, Cam *cam, qglviewer::Camera *view,
                const ObjectSet &objects, const QString &postSDL,
                const QString &sceneDir) {
  QFile file(path);
  file.open(QFile::WriteOnly | QFile::Truncate);

  QTextStream s(&file);

  s << "// Include file generated by Bullet Physics Playground" << "\n";
  s << "// " + byline << "\n";

  if (!preSDL.isEmpty()) {
    s << preSDL << "\n"
             << "\n";
  }

  if (cam != nullptr) {

    s << "#declare use_focal_blur = " << cam->getUseFocalBlur()
    << "; // 0=off 1=low quality 10=high quality" << "\n"
    << "\n";

    if (cam->getPreSDL().isNull()) {
      Vec pos = view->position();

      s << "camera { " << "\n"
               << "  location < " << pos.x << ", " << pos.y << ", " << -pos.z
               << " >" << "\n"
	           << "  right image_width/image_height*x" << "\n";

      Vec look = ((Cam *)view)->viewDirection() * 1000000 + view->position();
      s << "  look_at <" << look.x << ", " << look.y << ", " << -look.z
			   << "> ";

      // Keep the view's vertical field of view whatever the render's aspect
      // ratio; the horizontal angle POV-Ray wants follows from it.
      s << "  angle degrees(2*atan(tan(radians("
               << 180.0 * view->fieldOfView() / M_PI
               << ")/2)*image_width/image_height))" << "\n";

      s << "  sky <" << cam->getUpVector().x() << ", "
               << cam->getUpVector().y() << ", " << -cam->getUpVector().z()
               << ">" << "\n";

      s << "#if(use_focal_blur)" << "\n"
               << "  aperture " << cam->getFocalAperture() << "\n"
               << "  blur_samples 10*use_focal_blur" << "\n"
               << "  focal_point <" << cam->getFocalPoint().x() << ", "
               << cam->getFocalPoint().y() << ", " << -cam->getFocalPoint().z()
               << "> " << "  confidence 0.9+(use_focal_blur*0.0085)" << "\n"
               << "  variance 1/(2000*use_focal_blur)" << "\n"
               << "#end" << "\n";

      s << "}" << "\n"
               << "\n";
    } else {
      s << cam->getPreSDL() << "\n";
    }
  }

  foreach (Object *o, objects) {
    if (o->getPOVExport()) {
      Terrain *t = dynamic_cast<Terrain *>(o);
      if (t) {
        s << t->toPOV(sceneDir);
        continue;
      }
#ifdef HAS_LIB_ASSIMP
      Mesh *m = dynamic_cast<Mesh *>(o);
      if (m) {
        s << m->toPOV(sceneDir);
      } else {
      s << o->toPOV();
      }
#else
      s << o->toPOV();
#endif
    }
  }

  if (!postSDL.isEmpty()) {
    s << "\n"
             << postSDL << "\n"
             << "\n";
  }
}

void writeMakefile(const QString &sceneDir) {
  QString fileMakefile = QString("%1%2GNUmakefile").arg(qPrintable(sceneDir)).arg(QDir::separator());

  qDebug() << "GNUmakefile: " << fileMakefile;

  QFile file(fileMakefile);
  if (!file.exists()) {
    file.open(QFile::WriteOnly | QFile::Truncate);

    QTextStream mk(&file);
#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
    mk.setCodec("UTF-8"); // (Qt 6 always writes UTF-8)
#endif
    mk << "# GNUmakefile generated by Bullet Physics Playground ---------------------------\n";
    mk << "\n";
    mk << "SCENE = $(shell basename `pwd`)\n";
    mk << "\n";
    mk << QString::fromUtf8(EXPORT_MK);
    mk << "\n";
    mk << "# EOF --------------------------------------------------------------------------\n";
  }
}

} // namespace PovExport
