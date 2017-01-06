! Subroutine RCOLUM

! This software is part of the GLOW model.  Use is governed by the Open Source
! Academic Research License Agreement contained in the file glowlicense.txt.
! For more information see the file glow.txt.

! Stan Solomon, 1988, 1991
! Stan Solomon, 2016: removed problematic extrapolation below lower
! boundary.  If grazing height is below lower boundary of atmosphere
! supplied, column density is set to 1.0e30.
! Stan Solomon, 2016: refactored for f90.

! Calculates the column density ZCOL for each species ZMAJ above height
! ZZ at zenith angle CHI.  Calls subroutine VCD to calculate the
! vertical column density, and then uses a fit to the Chapman Grazing
! Incidence Integral [Smith and Smith, JGR 77, 3592, 1972] to calculate 
! the slant column density.  If CHI is less than 90 degrees, column
! densities are calculated directly; if CHI is greater than 90 degrees
! the column density at grazing height for 90 degrees is calculated and
! doubled, and the column density above ZZ(J) is subtracted.  If the
! grazing height is lower than the bottom of the atmosphere supplied, 
! column densities are set to 'infinity', i.e., 1.0e30.


    subroutine rcolum (chi, zz, zmaj, tn, zcol, zvcd, jmax, nmaj)

      parameter (nm=3)
      dimension zz(jmax), zmaj(nmaj,jmax), tn(jmax), zcol(nmaj,jmax), &
                zvcd(nmaj,jmax), zcg(nm)
      data pi/3.1415926535/, re/6.37e8/

      call vcd (zz, zmaj, zvcd, jmax, nmaj)

      if (chi .ge. 2.) then 
        do i=1,nmaj
          do j=1,jmax
            zcol(i,j) = 1.0e30
          enddo
        enddo
        return
      endif

      if (chi .le. pi/2.) then
        do i=1,nmaj
          do j=1,jmax
            zcol(i,j) = zvcd(i,j) * chap(chi,zz(j),tn(j),i)
          enddo
        enddo
      else
        do j=1,jmax
          ghrg=(re+zz(j))*sin(chi) 
          ghz=ghrg-re 
          if (ghz .le. zz(1)) then
            do i=1,nmaj
              zcol(i,j) = 1.0e30
            enddo
          else
            do k=1,j-1
              if (zz(k) .le. ghz .and. zz(k+1) .gt. ghz) then
                tng = tn(k)+(tn(k+1)-tn(k))*(ghz-zz(k))/(zz(k+1)-zz(k))
                do i=1,nmaj
                  zcg(i) = zvcd(i,k) * (zvcd(i,k+1) / zvcd(i,k)) ** &
                           ((ghz-zz(k)) / (zz(k+1)-zz(k)))
                enddo
              endif
            enddo
            do i=1,nmaj
              zcol(i,j) = 2. * zcg(i) * chap(pi/2.,ghz,tng,i) &
                        - zvcd(i,j) * chap(chi,zz(j),tn(j),i)
            enddo
          endif
        enddo
      endif

      return 
    end 



    function chap (chi, z, t, i)
      parameter (nmaj=3)
      dimension am(nmaj)
      data am/16., 32., 28./, pi/3.1415926535/, re/6.37e8/, g/978.1/
      gr=g*(re/(re+z))**2 
      hn=1.38e-16*t/(am(i)*1.662e-24*gr)
      hg=(re+z)/hn 
      hf=0.5*hg*(cos(chi)**2) 
      sqhf=sqrt(hf) 
      chap=sqrt(0.5*pi*hg)*sperfc(sqhf) 
      return
    end



    function sperfc(dummy) 
      if (dummy .le. 8.) then
        sperfc = (1.0606963+0.55643831*dummy) / &
                 (1.0619896+1.7245609*dummy+dummy*dummy)
      else
        sperfc=0.56498823/(0.06651874+dummy) 
      endif 
      return 
    end 



    subroutine vcd(zz,zmaj,zvcd,jmax,nmaj)
      dimension zz(jmax), zmaj(nmaj,jmax), zvcd(nmaj,jmax)
      do i=1,nmaj
        zvcd(i,jmax) =   zmaj(i,jmax) &
                       * (zz(jmax)-zz(jmax-1)) &
                       / alog(zmaj(i,jmax-1)/zmaj(i,jmax))
        do j=jmax-1,1,-1
          rat = zmaj(i,j+1) / zmaj(i,j)
          zvcd(i,j) = zvcd(i,j+1)+zmaj(i,j)*(zz(j)-zz(j+1))/alog(rat)*(1.-rat)
        enddo
      enddo
      return
    end
